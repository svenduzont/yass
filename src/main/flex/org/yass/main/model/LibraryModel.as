/*
 Copyright (c) 2008 Sven Duzont sven.duzont@gmail.com> All rights reserved.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"),
 to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is furnished
 to do so, subject to the following conditions: The above copyright notice
 and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS",
 WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
 TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
 OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
package org.yass.main.model{
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	import mx.events.CollectionEvent;
	
	import org.yass.Yass;
	import org.yass.debug.log.Console;
	import org.yass.main.events.LibraryEvent;
	import org.yass.main.events.PlayerEvent;
	import org.yass.util.tree.*;
	public class LibraryModel extends PlayListModel{
		public var genreArray:ArrayCollection;
		public var artistArray:ArrayCollection;
		public var albumArray:ArrayCollection;
		public static var trackInfos:Dictionary = new Dictionary();
		private var genreAll:ArrayCollection
		private var artistAll:ArrayCollection;
		private var albumAll:ArrayCollection;
		private var _tree:Tree;
		private var _sort:Sort = new Sort();
		private var _filteredText:Array;
		private var _filteredRating:int = 0;
		private var _genreFiltered:Array;
		private var _albumFiltered:Array;
		private var _artistFiltered:Array;
		private var _textFilterScope:String=TextFilterScope.ALL;
		private var _trackDictionary:Dictionary = new Dictionary();
		public function LibraryModel(libTreeData:Object, libraryData:Object):void{
			Console.group("model.Library :: Init");
			Console.time("TrackInfo tree extraction")
			_tree = new Tree(new XML(libTreeData));
			populateTree();
			Console.timeEnd("TrackInfo tree extraction")
			dispatchEvent(new LibraryEvent(LibraryEvent.REFRESHED, ["genre","artist", "album"]));
			_sort.fields = [new SortField("value")];
			Console.time("Track Array extraction")
			datas = new XML(libraryData).children()
			Console.timeEnd("Track Array extraction")
			Yass.player.addEventListener(PlayerEvent.TRACK_LOADED, onPlayerEvent);
			Yass.player.addEventListener(PlayerEvent.PLAYING, onPlayerEvent);
			Yass.player.addEventListener(PlayerEvent.STOPPED, onPlayerEvent);
			addEventListener(CollectionEvent.COLLECTION_CHANGE, onCollectionChange);
		}
   		public function set datas(value:Object):void{
			Console.log("model.PlayListModel.set datas");
			if(value is XMLList || value is ArrayCollection)
				for(var i:Object in value){
					var track:Track = new Track(value[i])
					addItem(_trackDictionary[track.id] = track);
				}
			else
				addItem(_trackDictionary[track.id] = track = new Track(value as XML));
   		}
   		public function getTrack(id:int):Track{
   			return _trackDictionary[id];
   		}
		private function populateTree():void{
			Console.group("model.Library.populateTree");
			genreArray = createArray("genre");
			artistArray = createArray("artist");
			albumArray = createArray("album");
			Console.groupEnd();
		}
		private function createArray(type:String):ArrayCollection{
			var array:ArrayCollection;
			if(_filteredText == null && _filteredRating == 0){
				if(this[type+"All"])
					return this[type+"All"]
				else{
					array = this[type+"All"] = _tree.getArrayByType(type);
					array.sort = _sort;
					array.refresh();
					for(var i:Object in array)
						trackInfos[array[i].id] = array[i]
				}
			}
			else
				array = this[type+"Array"] = new ArrayCollection(this["_" + type + "Filtered"]);
			Console.log("type:"+type+", length:"+array.length);
			return array;
		}
		public function browseBy(type:String, selectedItems:Array):void{
			Console.group("model.Library.browseBy : type="+type);
			Console.log("Items : " + selectedItems);
			Console.time("model.Library.browseby");
			var refreshedPanes:Array = new Array();
			if(selectedItems[0].id == -1){
				if(type == "genre"){
					genreSelected = new Array();
					artistSelected = new Array();
					albumSelected = new Array();
					artistArray.filterFunction = null;
					artistArray.refresh();
					albumArray.filterFunction = null;
					albumArray.refresh();
					refreshedPanes =  ["artist", "album"];
				}else if(type == "artist"){
					artistSelected = new Array();
					albumSelected = new Array();
					if(genreSelected.length >1)
						filterChild(albumArray, genreSelected);
					else{
						albumArray.filterFunction = null;
						albumArray.refresh();
					}
					refreshedPanes = ["album"];
				}
				if(type == "album")
					albumSelected = new Array();
			}
			else{
				if(type=="genre"){
					genreSelected = selectedItems;
					artistSelected = new Array();
					albumSelected = new Array();
					filterChild(artistArray, selectedItems);
					filterChild(albumArray, selectedItems);
					refreshedPanes = ["artist", "album"];
				} else if(type=="artist"){
					artistSelected = selectedItems;
					albumSelected = new Array();
					filterChild(albumArray, selectedItems);
					refreshedPanes = ["album"];
					if(!checkParent(selectedItems, genreSelected)){
						genreSelected = new Array()
						genreArray.filterFunction = null;
						genreArray.refresh();
						refreshedPanes.push("genre");
					}
					if(!artistSelected.every(function(obj:Object, index:int, arr:Array):Boolean{return artistArray.contains(obj)})){
						artistArray.filterFunction = null;
						artistArray.refresh();
						refreshedPanes.push("artist");
					}
				}
				else if(type == "album"){
					albumSelected = selectedItems;
					if(!checkParent(selectedItems, genreSelected)){
						genreSelected = new Array()
						genreArray.filterFunction = null;
						genreArray.refresh();
						refreshedPanes.push("genre");
					}
					if(!checkParent(selectedItems, artistSelected)){
						artistSelected = new Array()
						artistArray.filterFunction = null;
						artistArray.refresh();
						refreshedPanes.push("artist");
					}
					if(!albumSelected.every(function(obj:Object, index:int, arr:Array):Boolean{return albumArray.contains(obj)})){
						albumArray.filterFunction = null;
						albumArray.refresh();
					}
				}
			}

			if(_filteredText != null  && _filteredText.length > 0){
				var ffunction:Function = getTextFilterFunction();
				filterFunction = new LibraryfilterFunctions().getFilterFunction(_filteredRating, Yass.settings.genreSelected, Yass.settings.artistSelected, Yass.settings.albumSelected, ffunction, _filteredText)
			}
			else
				filterFunction = new LibraryfilterFunctions().getFilterFunction(_filteredRating, Yass.settings.genreSelected, Yass.settings.artistSelected, Yass.settings.albumSelected)
			Console.time("model.Library.refresh");
			refresh();
			Console.timeEnd("model.Library.refresh");
			Console.timeEnd("model.Library.browseby");
			Console.groupEnd();
			if(refreshedPanes.length> 0)
				dispatchEvent(new LibraryEvent(LibraryEvent.REFRESHED, refreshedPanes));
		}
		private function checkParent(itemsArray:Array, parentArray: Array):Boolean{
			if(parentArray.length == 0)
				return true;
			return itemsArray.every(function(item:Object, index:int, arr:Array):Boolean{
									var toret:Boolean= parentArray.every(function(parent:Object, index1:int, arr1:Array):Boolean{
											var toret1:Boolean=item.isChildOf(parent)
											return toret1;
										});
									return toret;
								});
		}
		public function set filteredText(txt:String):void{
			var ratingMatch:Array = txt.match(/\*+/)
			if(ratingMatch && ratingMatch.length > 0){	
				this._filteredRating = Math.min(ratingMatch[0].length, 5);
				txt = txt.replace("*", "");
			}		
			else
				_filteredRating = 0;
			_filteredText = txt.toLowerCase().split(/\W/).filter(function(row:Object, index:int, arr:Array):Boolean{return row && row != "";})
			filterText();
		}
		private function filterText():void{
			Console.group("model.Library.set filteredText:" + _filteredText);
			Console.time("model.Library.filterText");
			_genreFiltered = new Array();
			_artistFiltered = new Array();
			_albumFiltered = new Array();
			var genreSel:Array = genreSelected;
			var albumSel:Array = albumSelected;
			var artistSel:Array = artistSelected;
			var ffunction:Function = null;
			if(_filteredText != null && _filteredText.length > 0){
				// Here, the Genre, Artist, Album lists are refreshed according to the text typed in search field
				ffunction = getTextFilterFunction();
				source.forEach(
								function(row:Object, index:int, arr:Array):void{
									if(_filteredText.every(ffunction, row)){
										if(_genreFiltered.indexOf(row.genre) == -1)
											_genreFiltered.push(row.genre)
										if(_artistFiltered.indexOf(row.artist) == -1)
											_artistFiltered.push(row.artist)
										if(_albumFiltered.indexOf(row.album) == -1)
											_albumFiltered.push(row.album)
									}
								});
				genreSel = genreSelected.filter(function(obj:Object, index:int, arr:Array):Boolean{ return _genreFiltered.indexOf(obj) != -1})
				albumSel = albumSelected.filter(function(obj:Object, index:int, arr:Array):Boolean{ return _albumFiltered.indexOf(obj) != -1})
				artistSel = artistSelected.filter(function(obj:Object, index:int, arr:Array):Boolean{ return _artistFiltered.indexOf(obj) != -1})
			}
			else {
				if(_filteredRating > 0){
					source.forEach(
									function(row:Object, index:int, arr:Array):void{
										if(row.rating >= _filteredRating){
											if(_genreFiltered.indexOf(row.genre) == -1)
												_genreFiltered.push(row.genre)
											if(_artistFiltered.indexOf(row.artist) == -1)
												_artistFiltered.push(row.artist)
											if(_albumFiltered.indexOf(row.album) == -1)
												_albumFiltered.push(row.album)
										}
									});
					genreSel = genreSelected.filter(function(obj:Object, index:int, arr:Array):Boolean{ return _genreFiltered.indexOf(obj) != -1})
					albumSel = albumSelected.filter(function(obj:Object, index:int, arr:Array):Boolean{ return _albumFiltered.indexOf(obj) != -1})
					artistSel = artistSelected.filter(function(obj:Object, index:int, arr:Array):Boolean{ return _artistFiltered.indexOf(obj) != -1})
				}
				_filteredText = null
			}
			filterFunction = new LibraryfilterFunctions().getFilterFunction(_filteredRating, genreSel, artistSel, albumSel, ffunction, _filteredText)
			refresh();
			populateTree()
			if(genreSel.length > 0)
				filterChild(artistArray, genreSel);
			if(genreSel.length > 0)
				filterChild(albumArray, genreSel);
			Console.log("Filtered list length:" + length)
			Console.timeEnd("model.Library.filterText");
			Console.groupEnd();
			dispatchEvent(new LibraryEvent(LibraryEvent.REFRESHED, ["genre","artist", "album"]));
		}
		public function set textFilterScope(scope:String):void{
			_textFilterScope = scope;
			if(_filteredText && _filteredText.length !=0)
				filterText();
		}
		public function get textFilterScope():String{
			return _textFilterScope;
		}
		private function filterChild(sub:ArrayCollection,selectedItems:Array):void{
			Console.log("Filtering child with : " + selectedItems);
			var items:Array = new Array();
			for each(var item:Object in selectedItems)
				if(item is ValueMultiple){
					for each(var subItem:Value in item.values)
						if(genreSelected.length > 0 && genreSelected.lastIndexOf(subItem.parent) != -1)
							items.push(subItem);
						else if(genreSelected.length ==0)
							items.push(subItem);
				}
				else
					items.push(item)
			sub.filterFunction = function(rowVal:Value):Boolean{
									if(rowVal.id !=-1){
										for each(var toFilter:Value in items)
											if (rowVal.isChildOf(toFilter))
												return true;
										return false; }
									return true;
									};
			sub.refresh();
		}
		private function getTextFilterFunction():Function{
			if(_filteredRating > 0){
				
				switch(textFilterScope){
					case TextFilterScope.ALL :
						return function(obj:Object, index:int, arr:Array):Boolean{return this.allFields.indexOf(obj) != -1 && this.rating >= _filteredRating};
						break;
					case TextFilterScope.ARTISTS :
						return function(obj:Object, index:int, arr:Array):Boolean{return this.artist.lowerCaseValue.indexOf(obj) != -1 && this.rating >= _filteredRating};
						break;
					case TextFilterScope.ALBUMS :
						return function(obj:Object, index:int, arr:Array):Boolean{return this.album.lowerCaseValue.indexOf(obj) != -1 && this.rating >= _filteredRating};
						break;
					case TextFilterScope.TITLE :
						return function(obj:Object, index:int, arr:Array):Boolean{return this.lowerCaseTitle.indexOf(obj) != -1 && this.rating >= _filteredRating};
						break;
					};
			}
			else{
				switch(textFilterScope){
					case TextFilterScope.ALL :
						return function(obj:Object, index:int, arr:Array):Boolean{return this.allFields.indexOf(obj) != -1};
						break;
					case TextFilterScope.ARTISTS :
						return function(obj:Object, index:int, arr:Array):Boolean{return this.artist.lowerCaseValue.indexOf(obj) != -1};
						break;
					case TextFilterScope.ALBUMS :
						return function(obj:Object, index:int, arr:Array):Boolean{return this.album.lowerCaseValue.indexOf(obj) != -1};
						break;
					case TextFilterScope.TITLE :
						return function(obj:Object, index:int, arr:Array):Boolean{return this.lowerCaseTitle.indexOf(obj) != -1};
						break;
					};
			}
			return null;
		}

		public function get artistSelected():Array{
			return Yass.settings.artistSelected
		}
		public function get genreSelected():Array{
			return Yass.settings.genreSelected
		}
		public function get albumSelected():Array{
			return Yass.settings.albumSelected
		}
		public function set artistSelected(arr:Array):void{
			Yass.settings.artistSelected = arr
		}
		public function set genreSelected(arr:Array):void{
			Yass.settings.genreSelected = arr
		}
		public function set albumSelected(arr:Array):void{
			Yass.settings.albumSelected = arr
		}
	}
}	
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
 package org.yass.main.view{
    import flash.events.Event;
    import flash.utils.Dictionary;
    
    import mx.collections.Sort;
    import mx.collections.SortField;
    import mx.controls.DataGrid;
    import mx.controls.dataGridClasses.DataGridColumn;
    import mx.events.CollectionEvent;
    import mx.events.DataGridEvent;
    import mx.events.FlexEvent;
    import mx.events.ListEvent;
    
    import org.yass.Yass;
    import org.yass.debug.log.Console;
    import org.yass.main.controller.PlayListController;
    import org.yass.main.events.TrackEvent;
    import org.yass.main.model.interfaces.IPlayListModel;
    
    [Bindable]
    public class PlayListView  extends DataGrid   {
				
		public var playListId:String;
		private var sortA:Sort;
		private var sortByTrackNr:SortField;
		private var sortByArtist:SortField;
		private var sortByAlbum:SortField;
		private var sortByTitle:SortField;
		private var sortByLength:SortField;
		private var sortByRating:SortField;
		private var oldColumn:String;
		private var _model:IPlayListModel;
		private var playListColumns:Dictionary = new Dictionary();
		private var controller:PlayListController;

 		public function PlayListView(){	
 			super();
 			Console.log("view.PlayListView :: Init");
			this.doubleClickEnabled=true;
			this.allowMultipleSelection=true; 
			this.dragEnabled=true;
			this.addEventListener(DataGridEvent.HEADER_RELEASE, onHeaderClick);
 			this.addEventListener(ListEvent.ITEM_CLICK, onClick);
 			this.addEventListener(ListEvent.ITEM_DOUBLE_CLICK, onDoubleClick);
 			this.addEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);
 			// TODO :: Move this to the Model
 			sortA = new Sort();
			sortByAlbum = new SortField("album", true);
			sortByArtist = new SortField("artist", true);
			sortByTitle = new SortField("title", true);
			sortByTrackNr = new SortField("trackNr", true, false, true);
			sortByLength = new SortField("length", true, false, true);
			sortByRating = new SortField("rating", true, false, true);
 		}
 		
 		override protected function commitProperties():void{
 			super.commitProperties();
 		}
 		
 		/*
 		* The playList model associated with this view.
 		* called when a playlist have been returned from the Model after a server call
 		*/
		public function set model(value:IPlayListModel):void{
			this._model = value;
			_model.addEventListener(TrackEvent.TRACK_SELECTED, onTrackSelected);
			Console.group("view.PlayListView.setLoader : " + _model);
			model.bindDataProvider(this);
			playListId = model.playListId;
			// Remove the eventLoaders for a potentially previous controller
			if(controller)
				controller.destroy();
			this.controller = new PlayListController(this, value);
			// if the playlistModel is currently played, selecti the playing track
			if(Yass.player.isPlaying && Yass.player.loadedPlayList.playListId == playListId){
				this.selectedIndex = Yass.player.loadedPlayList.trackIndex;
				this.selectedIndex = Yass.player.loadedPlayList.datas.getItemIndex(Yass.player.loadedTrack);
			}
			Console.groupEnd();
		}
		public function get model():IPlayListModel{ 
			return _model;
		}		
 		/**
 		 * Called when a sort has occured, 
 		 * The sort logic :
 		 *  - sorted by artist, group the results by albums, then track number
 		 *  - sorted by albums, group the results by artists then track number
 		 *  - sorted by track number, group the results by artists then album
 		 *  TODO :: Move this to the Model
 		 */
		private function onHeaderClick(event:DataGridEvent):void {
			Console.group("view.PlayList.headerRelease column=" + event.dataField.toString());
			if (event.dataField.toString()=="trackNr") {
			    if(oldColumn == "trackNr")
			    	sortByTrackNr.reverse();
			 sortA.fields=[sortByTrackNr, sortByArtist, sortByAlbum, ];
			} else if (event.dataField.toString()=="album") {
			    if(oldColumn == "album")
			    	sortByAlbum.reverse();
			 sortA.fields=[sortByAlbum, sortByArtist, sortByTrackNr];
			} else if (event.dataField.toString()=="artist") {
			    if(oldColumn == "artist")
			    	sortByArtist.reverse();
			 sortA.fields=[sortByArtist, sortByAlbum, sortByTrackNr];
			   } else if (event.dataField.toString()=="title") {
			    if(oldColumn == "title")
			    	sortByTitle.reverse();
			   sortA.fields=[sortByTitle, sortByArtist, sortByAlbum];
			}else if (event.dataField.toString()=="length") {
			    if(oldColumn == "length")
			    	sortByLength.reverse();
			   sortA.fields=[sortByLength, sortByTitle, sortByArtist, sortByAlbum];
			} else if (event.dataField.toString()=="rating") {
			    if(oldColumn == "rating")
			    	sortByRating.reverse();
			   sortA.fields=[sortByRating, sortByArtist, sortByAlbum, sortByTrackNr];
			} 
			oldColumn = event.dataField.toString();
			// TODO :: Move this to the model
			this.model.datas.sort=sortA; 
			this.model.datas.refresh();
			this.model.datas.sort=null;
			event.preventDefault();
			Console.groupEnd();
		}

	 	

        /*
        * Called when a click has occured on the playlist, 
        * will dispatch a TrackEvent.TRACK_PLAY event to the MVC Controller 
        */
        public function onDoubleClick(event:Event):void{
			Console.group("view.PlayList.onDoubleClick");
		  	if(enabled){
				dispatchEvent(new TrackEvent(TrackEvent.TRACK_PLAY, selectedIndex, _model));
				this.collectionChangeHandler(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE));
		  	}
			Console.groupEnd();
        }
        /*
        * Called when a click has occured on the playlist, 
        * will dispatch a TrackEvent.TRACK_CLICK event to the MVC Controller 
        */
        public function onClick(event:Event):void{
			Console.group("view.PlayList.onClick");
        	if(enabled)
        		dispatchEvent(new TrackEvent(TrackEvent.TRACK_CLICK, selectedIndex, _model));
			Console.groupEnd();
        }
        // TODO : Move this to the model
		public function autoPlay():void{
			Console.group("view.PlayList.autoPlay :: requested");
			addEventListener(Event.ENTER_FRAME, function autoPlayAfterRefresh():void{
				if(enabled){
					Yass.player.loadedPlayList = _model;
					Console.log("view.PlayList.autoPlayDatagrid");
					removeEventListener(Event.ENTER_FRAME, autoPlayAfterRefresh);
					Yass.player.stop();
					Yass.player.loadedPlayList = model;
					Yass.player.play();
					this.collectionChangeHandler(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE));
					Console.log("view.PlayList.autoPlayDatagrid :: AutoPlay : OK");
				}
			});		
			Console.groupEnd();	
		}
		/**
		 * Called when an event occured from the Model (eg end of track, previous track
		 * Will cause the previously selected track to be displayed 
		 */
		public function onTrackSelected(evt:TrackEvent):void{
			Console.group("view.PlayList.onTrackSelected trackIndex=" + evt.trackIndex);
			if(evt.playList.playListId == this.playListId){
				this.collectionChangeHandler(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE));
				this.scrollToIndex(evt.trackIndex);
			}	
			Console.groupEnd();
		
		}
		/**
		 * 
		 */
		private function onCreationComplete(evt:FlexEvent):void{
			Console.group("view.PlayList.onCreationComplete");
			for each(var column:DataGridColumn in columns){
				if(column.dataField){
					Console.log(" Saving " +column.dataField);
					playListColumns[column.dataField] = column
				}
			}
			Console.groupEnd();
			
			
		}
    }
}
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
package org.yass.main.renderers{
	import flash.events.MouseEvent;
	
	import mx.controls.Button;
	import mx.controls.listClasses.IListItemRenderer;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	
	import org.yass.debug.log.Console;

	public class RatingRenderer extends UIComponent implements IListItemRenderer{

		private var img:Button = new Button();
		private var _data:Object;
		public function RatingRenderer() {
		
			img.addEventListener(MouseEvent.CLICK, click);
			img.setActualSize(69,12);
		}

		public function get data():Object{
			return _data;
		}

		public function set data(value:Object):void{
			if(value){
				_data = value;
				img.styleName = "rating" + _data.rating;
				invalidateProperties();
				dispatchEvent(new FlexEvent(FlexEvent.DATA_CHANGE));
			}
		}
		override protected function createChildren() : void{
			addChild(img);
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number ) : void{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			img.move(unscaledWidth/2 -35, unscaledHeight/2-6);
		}
		protected function click(evt:MouseEvent) : void{
			var oldRating:int = data.rating;
			data.rating = Math.floor(evt.localX / 14) +1;
			if(oldRating == data.rating && oldRating == 1)
				data.rating = 0;
			// Hack to force the refresh of the rating stars
			data = data;
			evt.stopPropagation();
		}
	}
}
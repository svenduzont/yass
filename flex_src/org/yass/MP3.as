package org.yass{
	import org.yass.main.model.PlayerModel;
	import org.yass.visualization.Display;
	public class MP3
	{
		public function MP3():void{			
		}
		public static var player:PlayerModel = PlayerModel.instance;

		public static function get display():Display{
			return Display.instance;
		}
		
		public static function get state():String{
			// Playlist
			var str:String = "[Player.loadedPlayList]";
			if(player.loadedPlayList){
				str += "\n";
				str += " - length " + player.loadedPlayList.length +"\n";
				str += " - selectedIndex : " + player.loadedPlayList.trackIndex +"\n";
	 			if( player.loadedTrack){
					str += " - loadedTrack.length : " +player.loadedTrack.length * 1000 +"\n";
					str += " - loadedTrack.UUID : " + player.loadedTrack.UUID +"\n";
	 			}
			}else
				str += " : NaN\n";
			// MP3 Player
			str += "\n[Player]";
			if(player){
				str += "\n";
				str += " - loop : " + player.loop +"\n";
				str += " - shuffle : " + player.shuffle +"\n";
				str += " - isPlaying : " + player.isPlaying +"\n";
				str += " - isPaused : " + player.isPaused +"\n";
				str += " - position : " + player.position +"\n";
				str += " - loadedLength : " + player.loadedLengh +"\n";
			}else
				str += " : NaN\n";
			// Display
			str += "\n[Display]";
			if(display){
				str += "\n";
				str += " - progress.maximum : " + display.progress.maximum + "\n";
				str += " - progress.value : " + display.progress.value + "\n";
				str += " - scrollText.running : " + display.scrollText.running + "\n";
				str += " - scrollText.currentIndex : " + display.scrollText.currentIndex +"\n";
			}else
				str += " : NaN\n";			
			str += " - display.currentDisplay :" +display.currentDisplay +"\n";
			
		return str;
		}
	}
} 
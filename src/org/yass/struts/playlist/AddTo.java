package org.yass.struts.playlist;

import org.yass.YassConstants;
import org.yass.domain.PlayList;
import org.yass.domain.SimplePlayList;
import org.yass.struts.YassAction;

public class AddTo extends YassAction implements YassConstants {

	public int id;
	public Integer[] trackIds;
	/**
	 * 
	 */
	private static final long serialVersionUID = 3411435373847531163L;

	public void setRefresh(final boolean refresh) {
	}

	@Override
	public String execute() {
		LOG.info("Adding trackis to playlist " + id);
		final PlayList pl = getPlayLists().get(id);
		if (pl instanceof SimplePlayList) {
			pl.add(trackIds);
			PLAYLIST_DAO.save(pl);
		}
		return NONE;
	}
}

package org.yass.struts.playlist;

import java.util.Iterator;

import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.yass.YassConstants;
import org.yass.domain.PlayList;
import org.yass.domain.SmartPlayList;
import org.yass.struts.YassAction;

public class Show extends YassAction implements YassConstants {

	public int id;
	/**
	 * 
	 */
	private static final long serialVersionUID = 3411435373847531163L;

	public void setRefresh(final boolean refresh) {
	}

	@Override
	public String execute() {
		try {
			LOG.info("Playlist id:" + id + " requested");
			final PlayList playList = getPlayLists().get(id);
			if (playList instanceof SmartPlayList)
				PLAYLIST_DAO.reloadSmartPlayLsit((SmartPlayList) playList);
			final Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().newDocument();
			final Node libNode = doc.appendChild(doc.createElement("playlist"));
			final Iterator<Integer> it = playList.getTrackIds().iterator();
			while (it.hasNext()) {
				final Element trackNode = (Element) libNode.appendChild(doc.createElement("track"));
				trackNode.setAttribute("id", it.next().toString());
			}
			return outputDocument(doc);
		} catch (final ParserConfigurationException e) {
			LOG.error("", e);
		}
		return NONE;
	}
}

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
package org.yass.rest;

import java.util.Collection;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.yass.YassConstants;
import org.yass.domain.Library;
import org.yass.domain.Track;
import org.yass.domain.TrackInfo;
import org.yass.domain.User;
import org.yass.util.XMLSerializer;

/**
 * @author Sven Duzont
 * 
 */
@Path("/users/{userId}/libraries/{libraryId}/trackinfos")
public class TrackInfosResource implements YassConstants {

	/**
     *
     */
	public static final Log LOG = LogFactory.getLog(TrackInfosResource.class);

	private boolean feedAlbum(final TrackInfo album, final Node artistNode) {
		final NodeList albLst = artistNode.getChildNodes();
		for (int k = 0; k < albLst.getLength(); k++)
			if (isNodeValue(album, albLst.item(k)))
				return true;
		artistNode.appendChild(album.toXMLElement(artistNode.getOwnerDocument()));
		return true;
	}

	private boolean feedArtist(final TrackInfo artist, final TrackInfo album, final Node genreNode) {
		final NodeList artistLst = genreNode.getChildNodes();
		for (int j = 0; j < artistLst.getLength(); j++) {
			final Node artistNode = artistLst.item(j);
			if (isNodeValue(artist, artistNode) && feedAlbum(album, artistNode))
				return true;
		}
		final Document doc = genreNode.getOwnerDocument();
		genreNode.appendChild(artist.toXMLElement(doc)).appendChild(album.toXMLElement(doc));
		return true;
	}

	private void feedGenre(final Element treeNode, final TrackInfo genre, final TrackInfo artist, final TrackInfo album) {
		final NodeList genreList = treeNode.getChildNodes();
		for (int i = 0; i < genreList.getLength(); i++) {
			final Element genreNode = (Element) genreList.item(i);
			if (isNodeValue(genre, genreNode) && feedArtist(artist, album, genreNode))
				return;
		}
		final Document doc = treeNode.getOwnerDocument();
		treeNode.appendChild(genre.toXMLElement(doc)).appendChild(artist.toXMLElement(doc)).appendChild(
				album.toXMLElement(doc));
	}

	/**
	 * 
	 * @param userId
	 * @return
	 * @throws javax.xml.parsers.ParserConfigurationException
	 */
	@GET
	@Produces(MediaType.APPLICATION_XML)
	public Response getTrackInfos(@PathParam("userId") final int userId, @PathParam("libraryId") final int libraryId)
			throws ParserConfigurationException {
		final User user = USER_DAO.findById(userId);
		if (user == null)
			return Response.status(Status.NOT_FOUND).type(MediaType.APPLICATION_XML).build();
		final Library lib = user.getLibrary(libraryId);
		if (lib == null)
			return Response.status(Status.NOT_FOUND).type(MediaType.APPLICATION_XML).build();
		final Collection<Track> tracks = lib.getTracks();
		final Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().newDocument();
		final Element treeNode = (Element) doc.appendChild(doc.createElement("libTree"));
		for (final Track track : tracks)
			feedGenre(treeNode, track.getTrackInfo(GENRE), track.getTrackInfo(ARTIST), track.getTrackInfo(ALBUM));
		doc.normalizeDocument();
		return Response.ok(XMLSerializer.serialize(doc), MediaType.APPLICATION_XML).build();
	}

	private boolean isNodeValue(final TrackInfo trackInfo, final Node node) {
		return ((Element) node).getAttribute("value").equals(trackInfo.getValue());
	}
}
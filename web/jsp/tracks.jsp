<?xml version="1.0" encoding="utf-8"?>
<%@page import="java.util.Iterator"%>
<%@page import="org.yass.domain.Track"%>
<%@page import="org.yass.domain.PlayList"%>
<%@page import="org.yass.YassConstants"%> 
<%@page import="org.apache.commons.lang.StringEscapeUtils"%>
<%@page import="org.yass.domain.Library"%><tracks><%
	Library lib  = (Library) application.getAttribute(YassConstants.ALL_LIBRARY);
	Iterator<Track> it = lib.getTracks().iterator();
	while(it.hasNext()){
		Track mf = it.next();
		if(mf.getTrackInfo(YassConstants.ARTIST) != null){
%>
 <track id="<%=mf.getId() %>" trackNr="<%=mf.getTrackNr() %>" title="<%=StringEscapeUtils.escapeXml(mf.getTitle())%>" artist="<%=mf.getTrackInfo(YassConstants.ARTIST).getId()%>" album="<%=mf.getTrackInfo(YassConstants.ALBUM).getId()%>" genre="<%=mf.getTrackInfo(YassConstants.GENRE).getId()%>" length="<%=mf.getLength() %>" rating="<%=mf.getRating() %>"/><%
		}
 	} 
 %> </tracks>
 
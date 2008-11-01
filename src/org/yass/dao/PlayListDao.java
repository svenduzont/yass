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
package org.yass.dao;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Date;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.jdbc.core.PreparedStatementCreator;
import org.springframework.jdbc.core.PreparedStatementCreatorFactory;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.simple.ParameterizedRowMapper;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.yass.domain.PlayList;
import org.yass.domain.SimplePlayList;
import org.yass.domain.SmartPlayList;
import org.yass.domain.SmartPlayListCondition;

public class PlayListDao extends AbstractDao {

	private static class PlayListRowMapper implements ParameterizedRowMapper<PlayList> {

		public PlayList mapRow(final ResultSet rs, final int rowNum) throws SQLException {
			final int id = rs.getInt(1);
			final int typeId = rs.getInt(2);
			final String name = rs.getString(3);
			final Date lastUpdate = rs.getDate(4);
			PlayListDao.LOG.info("Loading playlist id:" + id + " type:" + typeId);
			if (typeId == 0) {
				final PlayList pLst = new SimplePlayList(id, name, lastUpdate);
				final List<Map> lst = DaoHelper.getInstance().getJdbcTemplate().queryForList(
						"select track_id from simple_playlist where playlist_id = ?", new Object[] { pLst.getId() });
				for (final Map<String, Integer> map : lst)
					pLst.addTrack(map.get("TRACK_ID"));
				return pLst;
			} else {
				final Map map = DaoHelper.getInstance().getJdbcTemplate().queryForMap(
						"select max_tracks, order_by, operator from smart_playlist where playlist_id = ?", new Object[] { id });
				final SmartPlayList pLst = new SmartPlayList(id, name, ((Integer) map.get("MAX_TRACKS")).intValue(),
						((Integer) map.get("OPERATOR")).intValue(), ((String) map.get("ORDER_BY")));
				final List<Map> lst = DaoHelper.getInstance().getJdbcTemplate().queryForList(
						"select term, operator, value from smart_playlist_condition where playlist_id= ?", new Object[] { id });
				for (final Map<String, String> map1 : lst)
					pLst.getConditions().add(
							new SmartPlayListCondition(pLst, map1.get("TERM"), map1.get("OPERATOR"), map1.get("VALUE")));
				new PlayListDao().reloadSmartPlayLsit(pLst);
				return pLst;
			}
		}
	}

	private static final PlayListDao instance = new PlayListDao();
	private static final Log LOG = LogFactory.getLog(PlayListDao.class);

	/**
	 * @return the instance
	 */
	public static final PlayListDao getInstance() {
		return PlayListDao.instance;
	}

	private final PreparedStatementCreatorFactory pscf = new PreparedStatementCreatorFactory(
			"insert into playlist (type_id, user_id, name, last_update) values (?, ?, ?, ?) ");
	private final PlayListRowMapper rowMapper = new PlayListRowMapper();

	private PlayListDao() {
		pscf.addParameter(new SqlParameter("type_id", java.sql.Types.INTEGER));
		pscf.addParameter(new SqlParameter("user_id", java.sql.Types.INTEGER));
		pscf.addParameter(new SqlParameter("name", java.sql.Types.VARCHAR));
		pscf.addParameter(new SqlParameter("last_update", java.sql.Types.TIMESTAMP));
		pscf.setReturnGeneratedKeys(true);
	}

	public Map<Integer, PlayList> getFromUserId(final int userId) {
		PlayListDao.LOG.info("Loading Playlist from user_id:" + userId);
		final Map<Integer, PlayList> plsts = new LinkedHashMap<Integer, PlayList>();
		final Iterator<PlayList> it = getJdbcTemplate().query(
				"select id, type_id, name, last_update from playlist where user_id = ?", new Object[] { userId }, rowMapper)
				.iterator();
		while (it.hasNext()) {
			final PlayList plst = it.next();
			plsts.put(plst.getId(), plst);
		}
		PlayListDao.LOG.info("Playlists succefuly loaded " + plsts.size());
		return plsts;
	}

	public void reloadSmartPlayLsit(final SmartPlayList pLst) {
		final List<Map> lst = getJdbcTemplate().queryForList(pLst.getSqlStatement());
		pLst.setTrackIds(new LinkedHashSet<Integer>());
		for (final Map<String, Integer> map1 : lst)
			pLst.addTrack(map1.get("TRACK_ID"));
	}

	public void save(final PlayList plst) {
		PlayListDao.LOG.info("Saving PlayList");
		if (plst.getId() == 0) {
			final PreparedStatementCreator pst = pscf.newPreparedStatementCreator(new Object[] { plst.getTypeId(),
					plst.getUserId(), plst.getName(), plst.getLastUpdate() });
			final KeyHolder kh = new GeneratedKeyHolder();
			this.getJdbcTemplate().update(pst, kh);
			plst.setId(kh.getKey().intValue());
			PlayListDao.LOG.info(" new PlayList created id:" + plst.getId());
		} else {
			getJdbcTemplate().update("update playlist set name = ?, last_update = ?",
					new Object[] { plst.getName(), new Date() });
			if (plst instanceof SimplePlayList) {
				getJdbcTemplate().execute("delete from simple_playlist where playlist_id = " + plst.getId());
				int trackOrder = 0;
				for (final int trackId : plst.getTrackIds())
					getJdbcTemplate().update("insert into simple_playlist (playlist_id, track_id, track_order) values (?, ?, ?)",
							new Object[] { plst.getId(), trackId, trackOrder++ });
			}
		}
	}
}

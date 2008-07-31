package org.yass.dao.schema;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.jdbc.core.JdbcTemplate;

public class Schema00 extends Schema {

	private final static Log LOG = LogFactory.getLog(Schema00.class);

	@Override
	public void execute(final JdbcTemplate template) {
		LOG.info("Executing Schema check version 0.0.");
		if (!tableExists(template, "schema_version")) {
			LOG.info(" table 'schema_version' not found...");
			template.execute("create table schema_version (version int not null)");
			template.execute("insert into schema_version values (1)");
			LOG.info(" table 'schema_version' successfully created");
		}
		// Table 'Role'
		if (!tableExists(template, "role")) {
			LOG.info(" table 'role' not found...");
			template
					.execute("create table role (id int not null generated always as identity,name varchar(25) not null,primary key(id))");
			template.execute("insert  into role (name) values ('admin')");
			template.execute("insert into role (name) values ('playlist')");
			LOG.info(" table 'role' successfully created");
		}
		// Table 'yass_user'
		if (!tableExists(template, "yass_user")) {
			LOG.info(" table 'yass_user' not found.  Creating it.");
			template
					.execute("create table yass_user (id int not null generated always as identity, user_name varchar(25) not null, password varchar(25) not null,"
							+ " role_id int not null, primary key (id), foreign key (role_id) references role(id))");
			template.execute("insert  into yass_user (user_name, password, role_id) values ('admin', 'admin', 1)");
			LOG.info(" table 'yass_user' was created successfully.");
		}
		// Table 'library'
		if (!tableExists(template, "library")) {
			LOG.info(" table 'library' not found.  Creating it.");
			template
					.execute("create table library (id int not null generated always as identity, path varchar(512) not null, last_update timestamp not null, primary key(id))");
			LOG.info(" table 'library' was created successfully.");
		}
		// Table track_type
		if (!tableExists(template, "track_type")) {
			LOG.info(" table 'track_type' not found.  Creating it.");
			template
					.execute("create table track_type (id int not null, content_type varchar(64) not null, label varchar(64) not null, primary key(id))");
			template.execute("insert into track_type (id, content_type, label) values (1, 'audio/mp3', 'MP3')");
			template.execute("insert into track_type (id, content_type, label) values (2, 'audio/aac', 'AAC')");
			LOG.info(" table 'track_type' was created successfully.");
		}
		// Table 'track'
		if (!tableExists(template, "track")) {
			LOG.info(" table 'track' not found.  Creating it.");
			template
					.execute("create table track (id  int not null generated always as identity, library_id int not null, track_type_id integer not null, "
							+ "path varchar(512) not null, track_nr int, title varchar(256) not null,"
							+ "last_modified timestamp not null, length int not null,vbr int not null,"
							+ "primary key(id), foreign key(library_id) references library(id), "
							+ "foreign key(track_type_id) references track_type(id))");
			LOG.info(" table 'track' was created successfully.");
		}
		// Index IDX_track_01
		if (!indexExists(template, "IDX_track_01")) {
			LOG.info(" index IDX_track_01 on 'track' not found.  Creating it.");
			template
					.execute("create unique index IDX_track_01 on track (library_id, path, title, track_nr, length, last_update, track_type_id)");
			LOG.info(" index IDX_track_01 on 'track' was created successfully.");
		}
		// Table track_stats
		if (!tableExists(template, "track_stat")) {
			LOG.info(" table 'track_stat' not found.  Creating it.");
			template
					.execute("create table track_stat (user_id int not null, track_id int not null, rating int not null, last_played timestamp, play_count int not null, last_selected timestamp, "
							+ "foreign key(user_id) references yass_user(id), foreign key(track_id) references track(id))");
			LOG.info(" table 'track_stat' was created successfully.");
		}
		// Table track_info
		if (!tableExists(template, "track_info")) {
			LOG.info(" table 'track_info' not found.  Creating it.");
			template
					.execute("create table track_info (id  int not null generated always as identity, type varchar(64) not null, value varchar(128) not null, primary key(id))");
			LOG.info(" table 'track_info' was created successfully.");
		}
		// Index IDX_track_info_01
		if (!indexExists(template, "IDX_track_info_01")) {
			LOG.info(" index IDX_track_info_01 on 'track_track_info' not found.  Creating it.");
			template.execute("create unique index IDX_track_info_01 on track_info (type, value, id)");
			LOG.info(" index IDX_track_info_01 on 'track_track_info' was created successfully.");
		}
		// Index IDX_track_info_02
		if (!indexExists(template, "IDX_track_info_02")) {
			LOG.info(" index IDX_track_info_02 on 'track_track_info' not found.  Creating it.");
			template.execute("create unique index IDX_track_info_02 on track_info (id,type, value)");
			LOG.info(" index IDX_track_info_02 on 'track_track_info' was created successfully.");
		}
		// Table track_track�info
		if (!tableExists(template, "track_track_info")) {
			LOG.info(" table 'track_track_info' not found.  Creating it.");
			template.execute("create table track_track_info (track_id int not null, track_info_id int not null,"
					+ " foreign key(track_id) references track(id), " + " foreign key(track_info_id) references track_info(id))");
			LOG.info(" table 'track_track_info' was created successfully.");
		}
		// Index IDX_track_track_info_01
		if (!indexExists(template, "IDX_track_track_info_01")) {
			LOG.info(" index IDX_track_track_info_01 on 'track_track_info' not found.  Creating it.");
			template.execute("create unique index IDX_track_track_info_01 on track_track_info (track_id, track_info_id)");
			LOG.info(" index IDX_track_track_info_01 on 'track_track_info' was created successfully.");
		}
		// Table playlist_type
		if (!tableExists(template, "playlist_type")) {
			LOG.info(" table 'playlist_type' not found.  Creating it.");
			template.execute("create table playlist_type (id int not null, label varchar(16) not null, primary key(id))");
			template.execute("insert  into playlist_type (id, label) values (0, 'simple')");
			template.execute("insert  into playlist_type (id, label) values (1, 'smart')");
			LOG.info(" table 'playlist_type' was created successfully.");
		}
		// Table playlist
		if (!tableExists(template, "playlist")) {
			LOG.info(" table 'playlist' not found.  Creating it.");
			template
					.execute("create table playlist (id int not null generated always as identity, user_id int not null, type_id int not null, name varchar(128) not null, last_update timestamp"
							+ ", primary key(id), foreign key(user_id) references yass_user(id), foreign key(type_id) references playlist_type(id))");
			template.execute("insert into playlist (user_id, type_id, name) values(1, 1, 'Top rated')");
			template.execute("insert into playlist (user_id, type_id, name) values(1, 1, 'Most played')");
			LOG.info(" table 'playlist' was created successfully.");
		}
		// Table simple_playlist
		if (!tableExists(template, "simple_playlist")) {
			LOG.info(" table 'simple_playlist' not found.  Creating it.");
			template
					.execute("create table simple_playlist (playlist_id int not null, track_id int not null, track_order int not null"
							+ ", foreign key(playlist_id) references playlist(id), foreign key(track_id) references track(id))");
			LOG.info(" table 'simple_playlist' was created successfully.");
		}
		// Table smart_playlist
		if (!tableExists(template, "smart_playlist")) {
			LOG.info(" table 'smart_playlist' not found.  Creating it.");
			template
					.execute("create table smart_playlist (playlist_id int not null, max_tracks int not null, order_by varchar(50), operator int not null,"
							+ "foreign key(playlist_id) references playlist(id), primary key(playlist_id))");
			template
					.execute("insert into smart_playlist (playlist_id, max_tracks, order_by, operator) values (1,0,'rating desc', 0)");
			template
					.execute("insert into smart_playlist (playlist_id, max_tracks, order_by, operator) values (2,250,'play_count desc', 0)");
			LOG.info(" table 'smart_playlist' was created successfully.");
		}
		// Table smart_playlist_condition
		if (!tableExists(template, "smart_playlist_condition")) {
			LOG.info(" table 'smart_playlist_condition' not found.  Creating it.");
			template
					.execute("create table smart_playlist_condition (playlist_id int not null, term varchar(50) not null, operator varchar(12) not null, value varchar(128) not null,"
							+ "foreign key(playlist_id) references smart_playlist(playlist_id))");
			template
					.execute("insert into smart_playlist_condition (playlist_id, term, operator, value) values (1, 'rating', '>', '0')");
			template
					.execute("insert into smart_playlist_condition (playlist_id, term, operator, value) values (2, 'play_count', '>', '0')");
			LOG.info(" table 'smart_playlist_condition' was created successfully.");
		}
		// Table user_setting
		if (!tableExists(template, "user_setting")) {
			LOG.info(" table 'user_setting' not found.  Creating it.");
			template
					.execute("create table user_setting (user_id int not null, loaded_track_id int not null, volume int not null, shuffle smallint not null,"
							+ "repeat smallint not null, show_remaining smallint not null, display_mode smallint not null, stop_fadeout int not null,"
							+ "skip_fadeout int not null, next_fadeout int not null, foreign key(user_id) references yass_user(id))");
			LOG.info(" table 'user_setting' was created successfully.");
		}
		// Table user_browsing_context
		if (!tableExists(template, "user_browsing_context")) {
			LOG.info(" table 'user_browsing_context' not found.  Creating it.");
			template.execute("create table user_browsing_context (user_id int not null, track_info_id int not null"
					+ ", foreign key(user_id) references yass_user(id)"
					+ ", foreign key(track_info_id) references track_info(id))");
			LOG.info(" table 'user_browsing_context' was created successfully.");
		}
		// Table user_browsing_context
		if (!tableExists(template, "album_cover_picture")) {
			LOG.info(" table 'album_cover_picture' not found.  Creating it.");
			template
					.execute("create table album_cover_picture (track_info_id int not null, mime_type varchar(32) not null, description varchar(64) not null, picture_type smallint not null, picture_data blob(1M) not null"
							+ ", foreign key(track_info_id) references track_info(id))");
			LOG.info(" table 'album_cover_picture' was created successfully.");
		}
	}
}

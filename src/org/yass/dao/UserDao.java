package org.yass.dao;

import javax.persistence.EntityTransaction;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.yass.domain.User;

public class UserDao extends AbstractDao {

	private static final UserDao instance = new UserDao();
	private static final Log LOG = LogFactory.getLog(UserDao.class);

	private UserDao() {
	}

	public final User getFromId(final int id) {
		try {
			if (LOG.isDebugEnabled())
				LOG.debug("Get User id:" + id);
			return (User) getEntityManager().createNamedQuery("getUserById").setParameter(1, id).getSingleResult();
		} catch (final Exception e) {
			LOG.error("Error getting User id:" + id, e);
			return null;
		}
	}

	public final User save(final User user) {
		EntityTransaction transaction = null;
		try {
			if (LOG.isDebugEnabled())
				LOG.debug("Save User id:" + user.getId());
			transaction = getEntityManager().getTransaction();
			transaction.begin();
			getEntityManager().persist(user);
			transaction.commit();
		} catch (final Exception e) {
			LOG.error("Error saving loading User id:" + user.getId(), e);
			if (transaction != null)
				transaction.rollback();
		}
		return user;
	}

	/**
	 * @return the instance
	 */
	public static final UserDao getInstance() {
		return instance;
	}
}

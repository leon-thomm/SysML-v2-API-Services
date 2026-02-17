/*
 * SysML v2 REST/HTTP Pilot Implementation
 * Copyright (C) 2020 InterCAX LLC
 * Copyright (C) 2020 California Institute of Technology ("Caltech")
 * Copyright (C) 2021 Twingineer LLC
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * @license LGPL-3.0-or-later <http://spdx.org/licenses/LGPL-3.0-or-later>
 */

package jpa.manager.impl;

import jpa.manager.JPAManager;

import javax.inject.Singleton;
import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;
import javax.persistence.Persistence;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Consumer;
import java.util.function.Function;

@Singleton
public class HibernateManager implements JPAManager {
    public static final String PERSISTENCE_UNIT_NAME = "sysml2-hibernate";

    private final EntityManagerFactory entityManagerFactory;

    public HibernateManager() {
        Map<String, String> properties = new HashMap<>();
        
        // Override database connection properties with environment variables if provided
        // Note: No validation is performed to allow falling back to persistence.xml defaults
        // In production deployments, ensure environment variables are properly set
        String dbHost = System.getenv("DB_HOST");
        String dbPort = System.getenv("DB_PORT");
        String dbName = System.getenv("DB_NAME");
        String dbUser = System.getenv("DB_USER");
        String dbPassword = System.getenv("DB_PASSWORD");
        
        if (dbHost != null && dbPort != null && dbName != null) {
            String jdbcUrl = String.format("jdbc:postgresql://%s:%s/%s", dbHost, dbPort, dbName);
            properties.put("javax.persistence.jdbc.url", jdbcUrl);
        }
        
        if (dbUser != null) {
            properties.put("javax.persistence.jdbc.user", dbUser);
        }
        
        if (dbPassword != null) {
            properties.put("javax.persistence.jdbc.password", dbPassword);
        }
        
        // Create EntityManagerFactory with overridden properties if any
        if (properties.isEmpty()) {
            entityManagerFactory = Persistence.createEntityManagerFactory(PERSISTENCE_UNIT_NAME);
        } else {
            entityManagerFactory = Persistence.createEntityManagerFactory(PERSISTENCE_UNIT_NAME, properties);
        }
    }

    @Override
    public String getPersistenceUnitName() {
        return PERSISTENCE_UNIT_NAME;
    }

    @Override
    public EntityManagerFactory getEntityManagerFactory() {
        return entityManagerFactory;
    }

    @Override
    public <R> R transact(Function<EntityManager, R> function) {
        EntityManager entityManager = getEntityManagerFactory().createEntityManager();
        try {
            return function.apply(entityManager);
        } finally {
            entityManager.close();
        }
    }

    @Override
    public void transact(Consumer<EntityManager> consumer) {
        EntityManager entityManager = getEntityManagerFactory().createEntityManager();
        try {
            consumer.accept(entityManager);
        } finally {
            entityManager.close();
        }
    }
}

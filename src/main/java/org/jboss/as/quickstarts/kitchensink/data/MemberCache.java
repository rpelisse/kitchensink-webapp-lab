package org.jboss.as.quickstarts.kitchensink.data;

import java.util.ArrayList;
import java.util.List;

import javax.annotation.PostConstruct;
import javax.enterprise.context.ApplicationScoped;

import org.infinispan.client.hotrod.RemoteCache;
import org.infinispan.client.hotrod.RemoteCacheManager;
import org.infinispan.client.hotrod.configuration.ConfigurationBuilder;
import org.jboss.as.quickstarts.kitchensink.model.Member;

@ApplicationScoped
public class MemberCache {

	private final static String MEMBERS = "members";

	private RemoteCacheManager cacheManager;
	private RemoteCache<String,List<Member>> cache;

	@PostConstruct
	public void init() {
		cacheManager = new RemoteCacheManager(configureBuilder().build());
		cache = cacheManager.getCache("default");
	}

	private ConfigurationBuilder configureBuilder() {
		System.out.println("HotRod Service:" + System.getenv("HOTROD_SERVICE"));
		System.out.println("HotRod Service Port:" + System.getenv("HOTROD_SERVICE_PORT"));
		ConfigurationBuilder builder = new ConfigurationBuilder();
		builder.addServer().host(System.getenv("HOTROD_SERVICE"))
		.port(Integer.parseInt(System.getenv("HOTROD_SERVICE_PORT")));
		return builder;
	}

	public List<Member> loadFromCache() {
		if ( cache.containsKey(MEMBERS))
			return cache.get(MEMBERS);
		return new ArrayList<Member>(0);
	}

	public void loadIntoCache(List<Member> members) {
		cache.put(MEMBERS, members);
	}

	public void invalidateCache() {
		cache.clear();
	}

	public Member findMemberBy(long id) {
		throw new UnsupportedOperationException("not implemented yet");
	}
}

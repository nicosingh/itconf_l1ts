class profile::it::grafana {
	class { 'grafana': 
		version => lookup("grafana_version")
	}

	# Can be fixed once we manage to fix the issue with Hiera ssh key
	file{ "/root/.ssh":
		ensure => directory,
		mode => "600"
	}

	file{ "/root/.ssh/known_hosts":
		ensure => present,
		require => File["/root/.ssh/"]
	}

	#TODO to be removed:
	#########################################################
	file{"/root/.ssh/id_rsa":
		ensure => file,
		content => lookup("temp_ssh"),
		require => File["/root/.ssh/"],
		mode => "600"
	}

	file{"/root/.ssh/id_rsa.pub":
		ensure => file,
		content => lookup("temp_ssh_pub"),
		require => File["/root/.ssh/"],
		mode => "600"
	}

	#########################################################

	package{"epel-release":
		ensure => installed
	}

	package{"python36":
		ensure => installed,
		require => Package["epel-release"]
	}

	package{"python36-requests":
		ensure => installed,
		require => Package["epel-release"]
	}

	exec{"Ensure pip3.6 exists":
		path  => [ '/usr/bin', '/bin', '/usr/sbin' ], 
		command => "python3.6 -m ensurepip",
		onlyif => "test ! -f /usr/local/bin/pip3.6",
		require => Package["python36"]
	}

	exec{"Installing PyYAML":
		path  => [ '/usr/bin', '/bin', '/usr/sbin' , '/usr/local/bin'], 
		command => "pip3.6 install PyYAML",
		onlyif => "[ -z \"$(pip3.6 list | grep PyYAML -o)\" ]",
		require => [Package["python36"], Exec["Ensure pip3.6 exists"]]
	}

	$organizations_gitrepo = lookup("organizations_gitrepo")

	$organizations_gitrepo.each | $orgname, $org| {

		file{"/root/.ssh/${orgname}_id_rsa":
			ensure => file,
			content => $org["id_rsa"],
			require => File["/root/.ssh/"],
			mode => "600"
		}

		file{"/root/.ssh/${orgname}_id_rsa.pub":
			ensure => file,
			content => $org["id_rsa.pub"],
			require => File["/root/.ssh/"],
			mode => "600"
		}

		vcsrepo { "/etc/grafana/lsst/inputs/$orgname":
			ensure => latest, # This download always the latest version of the repo
			provider => git,
			source => $org["repo"],
			branch => $org["branch"],
			require => [File["/etc/grafana/lsst"], Exec["github-to-known-hosts"]],
			before => Exec["Run gpInputs.py"],
			notify => Service["grafana-server"],
			identity => "/root/.ssh/${orgname}_id_rsa"
		}

		$org["plugins"].each | $plugin_name | {
			grafana_plugin { $plugin_name:
				ensure => present,
				require => File["/var/lib/grafana/plugins"]
			}
		}
	}

	exec{"github-to-known-hosts":
		path => "/usr/bin/",
		command => "ssh-keyscan github.com > /root/.ssh/known_hosts",
		onlyif => "test -z \"$(grep github.com /root/.ssh/known_hosts -o)\"",
		require => File["/root/.ssh/known_hosts"]
	}

	vcsrepo { "/opt/GrafanaProvisioning":
		ensure => present,
		provider => git,
		source => "git@github.com:Frakenz/GrafanaProvisioning.git",
		branch => "release_1",
		require => [Exec["github-to-known-hosts"]]
	}

	file{ "/etc/grafana/lsst/":
		ensure => 'directory',
		recurse => true,
 		source => "file:////opt/GrafanaProvisioning/GrafanaProvisioning",
		require => [Vcsrepo["/opt/GrafanaProvisioning"]]
	}

	exec{ "Run gpSetup.py":
		path  => [ '/usr/bin', '/bin', '/usr/sbin' ], 
		cwd => "/etc/grafana/lsst/",
		command => "python3.6 gpSetup.py",
		require => [Package["python36-requests"], Exec["Installing PyYAML"], File["/etc/grafana/lsst/"], Class["grafana"]],
		before => [Firewalld_port["Grafana Main Port"]]
	}

	firewalld_port { 'Grafana Main Port':
		ensure   => present,
		port     => '3000',
		protocol => 'tcp',
		require => Service['firewalld'],
	}

	exec{ "Run gpInputs.py":
		path  => [ '/usr/bin', '/bin', '/usr/sbin' ], 
		cwd => "/etc/grafana/lsst/",
		command => "python3.6 gpInputs.py",
		require => Exec["Run gpSetup.py"],
		notify => File["/etc/grafana/lsst/restart.txt"]
	}

	exec{ "Run gpAccounts.py":
		path  => [ '/usr/bin', '/bin', '/usr/sbin' ], 
		cwd => "/etc/grafana/lsst/",
		command => "python3.6 gpAccounts.py",
		require => Exec["Run gpInputs.py"],
	}

	file{ ["/etc/grafana/provisioning/", "/etc/grafana/provisioning/dashboards", "/etc/grafana/provisioning/datasources"] :
		ensure => directory,
		owner => root,
		group => grafana,
		mode => "755",
		before => Exec["Run gpInputs.py"]
	}

	if ! defined( File["/var/lib/grafana/plugins"] ){
		file{ "/var/lib/grafana/plugins":
			ensure => directory,
			owner => grafana,
			group => grafana,
			mode => "750",
		}
	}

	file{ "/etc/grafana/lsst/restart.txt" :
		ensure => "absent",
		notify => Exec["On Demand grafana-server restart"],
	}

	exec{ "On Demand grafana-server restart":
		path  => [ '/usr/bin', '/bin', '/usr/sbin' ], 
		command => "systemctl restart grafana-server",
		refreshonly => true,
	}

}

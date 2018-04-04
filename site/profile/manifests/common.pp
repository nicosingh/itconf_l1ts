#This base installation is based on the procedure
# https://confluence.lsstcorp.org/display/IT/Linux+CentOS+Setup
class profile::common {
 	include profile::ssh_server

	package { 'nmap':
		ensure => installed,
	}

	package { 'vim':
		ensure => installed,
	}

	package { 'wget':
		ensure => installed,
	}

	# I would like to confirm if there is any particular version of gcc to be installed
	package { 'gcc':
		ensure => installed,
	}

	package { 'xinetd':
		ensure => installed,
	}

	package { 'tcpdump':
		ensure => installed,
	}

	package { 'openssl':
		ensure => installed,
	}

	package { 'openssl-devel':
		ensure => installed,
	}

	package { 'telnet':
		ensure => installed,
	}

	package { 'acpid':
		ensure => installed,
	}

	package { 'lvm2':
		ensure => installed,
	}

	package { 'firewalld':
		ensure => installed,
	}
	
	service{ 'firewalld':
		ensure => running,
		enable => true,
	}

################################################################################
	$ntp = lookup('ntp')
	class { '::chrony':
		servers => {
			"${$ntp[ntp_server_1]}" => ['iburst'],
			"${$ntp[ntp_server_2]}" => ['iburst'],
			"${$ntp[ntp_server_3]}" => ['iburst'],
		},
	}

	$motd_msg = lookup('motd')
	file { '/etc/motd' :
		ensure => file,
		content => $motd_msg,
	}

################################################################################

	# as per /etc/login.defs, max uid is 999, so we have set 777 as the default group admin account
	group { 'sysadmin':
		ensure => present,
		gid => 777,
		auth_membership => true,
		members => ['sysadmin']
	}

	#current user for sudo access is wheel, in centos 7 it has GID=10
	group { 'wheel':
		ensure => present,
		gid => 10,
		auth_membership => true,
		members => ['sysadmin'],
		require => Group['sysadmin'],
	}

	# as per /etc/login.defs, max uid is 999, so we have set 777 as the default group admin account
	user{ 'sysadmin':
		ensure => 'present',
		uid => '777' ,
		gid => '777',
		home => '/home/sysadmin',
		managehome => true
	}

	file{ '/home/sysadmin':
		ensure => directory,
		mode => '700',
		require => User['sysadmin'],
	}

	file_line { 'SELINUX=permissive':
		path  => '/etc/selinux/config',
		line => 'SELINUX=enforce',
		match => '^SELINUX=+',
	}

	# Set timezone as default to UTC
	exec { 'set-timezone':
		command => '/bin/timedatectl set-timezone UTC',
		returns => [0],
	}
  
# Shared resources from all the teams

	package { 'git':
		ensure => present,
	}

	group { 'lsst':
		ensure => present,
		gid => 500,
		auth_membership => true,
		members => ['sysadmin'],
	}
	
# group/user creation

	#TODO Move password to hiera
	user{ 'lsstmgr':
		ensure => 'present',
		uid => '500' ,
		gid => '500',
		home => '/home/lsstmgr',
		managehome => true,
		require => Group['lsst'],
		password => '$1$PMfYrt2j$DAkeHmsz1q5h2XUsMZ9xn.',
	}

	user{ 'tcsmgr':
		ensure => 'present',
		uid => '502' ,
		gid => '500',
		home => '/home/tcsmgr',
		managehome => true,
		require => Group['lsst'],
		password => '$1$PMfYrt2j$DAkeHmsz1q5h2XUsMZ9xn.',
	}

	user{ 'tcs':
		ensure => 'present',
		uid => '504' ,
		gid => '500',
		home => '/home/tcs',
		managehome => true,
		require => Group['lsst'],
		password => '$1$PMfYrt2j$DAkeHmsz1q5h2XUsMZ9xn.',
	}

}

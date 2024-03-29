# Class to configure the software from the dome, which includes labview installation/configuration
class profile::ts::ts_dome{
  include ts_sal
  $labview_version = lookup('ts::ts_dome::labview_version')

  class{'ts_xml':
    ts_xml_path       => lookup('ts_xml::ts_xml_path'),
    ts_xml_subsystems => lookup('ts::ts_dome::ts_xml_subsystems'),
    ts_xml_languages  => lookup('ts::ts_dome::ts_xml_languages'),
    ts_sal_path       => lookup('ts_sal::ts_sal_path'),
  }

  if $labview_version == '2015' {
    exec{ 'get_labview':
      path    => ['/bin','/usr/sbin', '/usr/bin'],
      command => 'mkdir /tmp/lvruntime2015 && \
                  /usr/bin/wget http://download.ni.com/support/softlib/labview/labview_runtime/2015/Linux/f3/LabVIEW2015RTE_Linux.tgz \
                  -O /tmp/lvruntime2015/LabVIEW2015RTE_Linux.tgz',
      notify  => Exec['install_labview'],
      onlyif  => 'test ! -d /tmp/lvruntime2015 && test ! -d /etc/natinst/ && test ! -d /usr/local/natinst/'
    }

  }elsif $labview_version == '2016'{
    exec{ 'get_labview':
      path    => ['/bin','/usr/sbin'],
      command => 'mkdir /tmp/lvruntime2016 && \
                  /usr/bin/wget http://download.ni.com/support/softlib/labview/labview_runtime/2016/Linux/f5/64-bit/LabVIEW2016RTE_Linux.tgz \
                  -O /tmp/lvruntime2016/LabVIEW2016RTE_Linux.tgz',
      notify  => Exec['install_labview'],
      onlyif  => 'test ! -d /tmp/lvruntime2016 && test ! -d /etc/natinst/ && test ! -d /usr/local/natinst/'
    }
  }

  exec{'install_labview':
    path    => ['/bin','/usr/sbin', '/usr/bin'],
    command => "cd /tmp/lvruntime${$labview_version}/ && tar -xvzf LabVIEW${$labview_version}RTE_Linux.tgz && ./INSTALL",
    require => Exec['get_labview'],
    onlyif  => "test ! -f /tmp/lvruntime${$labview_version}/LabVIEW${$labview_version}RTE_Linux.tgz && \
                test ! -d /etc/natinst/ && \
                test -d /usr/local/natinst/"
  }

}

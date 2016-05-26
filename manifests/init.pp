# Copyright 2011 MaestroDev
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
class sonarqube (
  $version          = '5.5',
  $user             = 'sonar',
  $group            = 'sonar',
  $user_system      = true,
  $host             = undef,
  $port             = 9000,
  $portAjp          = -1,
  $context_path     = '/',
  $https            = {},
  $ldap             = {},
  # ldap and pam are mutually exclusive. Setting $ldap will annihilate the setting of $pam
  $pam              = {},
  $crowd            = {},
  $jdbc             = {
    url                               => 'jdbc:h2:tcp://localhost:9092/sonar',
    username                          => 'sonar',
    password                          => 'sonar',
    max_active                        => '50',
    max_idle                          => '5',
    min_idle                          => '2',
    max_wait                          => '5000',
    min_evictable_idle_time_millis    => '600000',
    time_between_eviction_runs_millis => '30000',
  },
  $updatecenter     = true,
  $http_proxy       = {},
  $profile          = false,
  $web_java_opts    = undef,
  $search_java_opts = undef,
  $search_host      = '127.0.0.1',
  $search_port      = '9001',
  $config           = undef,
){
  if $::osfamily == 'RedHat' {
    $sonar_package = "sonar-${version}-1"

    yumrepo { 'sonar':
      ensure   => present,
      name     => 'sonar',
      descr    => 'native sonar packages',
      baseurl  => 'http://downloads.sourceforge.net/project/sonar-pkg/rpm',
      gpgcheck => false,
      enabled  => true,
    }

    package { $sonar_package:
      ensure  => present,
      require => Yumrepo['sonar'],
    }
  } else {
    fail("${::operatingsystem} is not supported by ${::module}")
  }

  user { $user:
    ensure     => present,
    home       => '/opt/sonar',
    managehome => false,
    system     => $user_system,
  } ->
  group { $group:
    ensure => present,
    system => $user_system,
  }

  # Sonar configuration files
  if $config != undef {
    file { '/opt/sonar/conf/sonar.properties':
      source => $config,
      notify => Service['sonarqube'],
      mode   => '0600',
    }
  } else {
    file { '/opt/sonar/conf/sonar.properties':
      content => template('sonarqube/sonar.properties.erb'),
      notify  => Service['sonarqube'],
      mode    => '0600',
    }
  }

  service { 'sonarqube':
    ensure     => running,
    name       => 'sonar',
    hasrestart => true,
    hasstatus  => true,
    enable     => true,
    require    => Package[$sonar_package],
  }

}

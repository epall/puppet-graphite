# == Class: graphite::config_nginx
#
# This class configures nginx to talk to graphite/carbon/whisper and SHOULD
# NOT be called directly.
#
# === Parameters
#
# None.
#

include nginx

class graphite::config_nginx inherits graphite::params {
  Exec { path => '/bin:/usr/bin:/usr/sbin' }

  if $::osfamily != 'debian' {
    fail("nginx-based graphite is not supported on ${::operatingsystem} (only supported on Debian)")
  }

  Package['nginx'] -> Exec['Chown graphite for web user']
  Package['nginx'] ~> Exec['Chown graphite for web user']

  # Deploy configfiles

  file {
    '/etc/nginx/sites-available/graphite':
      ensure  => file,
      mode    => '0644',
      content => template('graphite/etc/nginx/sites-available/graphite.erb'),
      require => [
        File['/etc/nginx/sites-available'],
        Exec['Initial django db creation'],
        Exec['Chown graphite for web user']
      ],
      notify  => Service['nginx'];

    '/etc/nginx/sites-enabled/graphite':
      ensure  => link,
      target  => '/etc/nginx/sites-available/graphite',
      require => [
        File['/etc/nginx/sites-available/graphite'],
        File['/etc/nginx/sites-enabled']
      ],
      notify  => Service['nginx'];
  }

  # HTTP basic authentication
  $nginx_htpasswd_file_presence = $::graphite::nginx_htpasswd ? {
    undef   => absent,
    default => file,
  }

  file {
    '/etc/nginx/graphite-htpasswd':
      ensure  => $nginx_htpasswd_file_presence,
      mode    => '0400',
      owner   => $::graphite::params::web_user,
      content => $::graphite::nginx_htpasswd,
      require => Package['nginx'],
      notify  => Service['nginx'];
  }
}

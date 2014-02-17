define dodrupal::base (

  # class arguments
  # ---------------
  # setup defaults

  $user = 'web',
  $group = 'www-data',

  # drupal install details
  $site_name = 'Devopera Drupal Demo',
  $admin_user = 'admin',
  $admin_email = 'root@localhost',
  $admin_password = 'admLn**',
  $version = 'drupal-7',
  $vhost_seq = '00',

  # database connection values
  $db_type = 'mysql',
  $db_name_prepend = 'dodrupal',
  $db_user_prepend = 'do',
  $db_pass = 'admLn**',
  $db_host = 'localhost',
  $db_port = '3306',
  $db_grants = ['all'],

  # install directory
  $target_dir = '/var/www/html',
  
  # don't monitor by default, because site content will change for most people
  $monitor = false,

  # end of class arguments
  # ----------------------
  # begin class

) {
  # configure database name
  $db_name = "${db_name_prepend}-${version}"
  $db_user = "${db_user_prepend}-${version}"

  # monitor if turned on
  if ($monitor) {
    class { 'dodrupal::monitor' : 
      site_name => $site_name, 
    }
  }

  # only install drupal if not already there
  dodrupal::drush { "install-drupal-${title}":
    command => "dl ${version} -q --drupal-project-rename='${version}'",
    cwd => "${target_dir}/",
    cwd_check => false,
    user => $user,
    group => $group,
    require => Docommon::Stickydir["${target_dir}"],
    creates => "${target_dir}/${version}/.htaccess",
  }->
  
  # always update the existing install, even if redundant
  dodrupal::drush { "update-drupal-${title}":
    command => 'up -y -q --no-backup',
    cwd => "${target_dir}/${version}",
    cwd_check => false,
    user => $user,
    group => $group,
    onlyif => "test -f ${target_dir}/${version}/sites/default/settings.php"
  }

  # create symlink from our home folder
  file { "/home/${user}/${version}":
    ensure => 'link',
    target => "${target_dir}/${version}",
    require => Dodrupal::Drush["install-drupal-${title}"],
  }

  # setup vhost from template as root:root
  include 'apache::params'
  file { "dodrupal-vhost-conf-${title}" :
    path => "${apache::params::vhost_dir}/vhost-${vhost_seq}-${version}.conf",
    content => template('dodrupal/vhosts-dodrupal.conf.erb'),
  }->
  exec { "dodrupal-vhosts-refresh-apache-${title}":
    path => '/bin:/usr/bin:/sbin:/usr/sbin',
    command => "service ${apache::params::apache_name} graceful",
    tag => ['service-sensitive'],
  }
  
  # Debian derivatives also require an enable step
  case $::operatingsystem {
    ubuntu, debian: {
      exec { "dodrupal-vhost-conf-a2ensite-${title}" :
        path => '/bin:/usr/bin:/sbin:/usr/sbin',
        command => "a2ensite vhost-${vhost_seq}-${version}.conf",
        before => [Exec["dodrupal-vhosts-refresh-apache-${title}"]],
        require => [File["dodrupal-vhost-conf-${title}"]],
      }
    }
  }

  # ensure files directories are web accessible
  docommon::stickydir { "dodrupal-writeable-files-${title}" :
    user => $user,
    group => $group,
    mode => 6660,
    groupfacl => 'rwx',
    recurse => true,
    filename => "${target_dir}/${version}/sites/default/files",
    require => [File['/var/www/git/github.com'], Dodrupal::Drush["install-drupal-${title}"]],
  }

  # create a mysql database for Drupal, then always install a fresh DB and setup the admin user
  $db_url = "${db_type}://${db_user}:${db_pass}@${db_host}:${db_port}/${db_name}"
  notify { "debug-db-url-${title}":
    message => ">>${db_url}<<",
  }
  mysql::db { "${db_name}":
    user     => $db_user,
    password => $db_pass,
    host     => $db_host,
    grant    => $db_grants,
  }->
  # build drupal database
  dodrupal::drush { "install-site-and-admin-user-${title}":
    command =>
      "site-install --yes  --site-name=\"${site_name}\" --db-url=${db_url} --account-name=${admin_user} --account-pass=${admin_password}",
    cwd => "${target_dir}/${version}",
    user => $user,
    group => $group,
    # don't build if we find an existing database, indicated by a 'node' table
    onlyif => "bash -c \"test `mysqlshow -u ${db_user} --password='${db_pass}' ${db_name} | grep 'node ' | wc -l` == 0\"",
    require => [Dodrupal::Drush["install-drupal-${title}"]],
  }
}

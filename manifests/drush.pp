define dodrupal::drush (

  # define arguments
  # ---------------
  # setup defaults

  $command = $title,
  $cwd = '/var/www',
  $user = 'web',
  $group = 'www-data',
  $cwd_check = true,
  $creates = undef,
  $onlyif = 'true',

  # end of define arguments
  # ----------------------
  # begin define

) {
  if ($cwd_check == true) {
    # check the current working directory exists, or else create it
    file { "drush-${title}-${cwd}" :
      path => $cwd,
      ensure => directory,
      owner => $user,
      group => $group,
      before => Exec["drush-${title}"], 
    }
  }
  # run drush
  exec { "drush-${title}":
    path => '/usr/bin:/bin:/usr/local/zend/bin/',
    command => "bash -c 'cd ${cwd}; drush ${command}'",
    user => $user,
    group => $group, 
    creates => $creates,
    require => Class['dodrupal'],
    onlyif => $onlyif,
    provider => 'shell',
  }
}

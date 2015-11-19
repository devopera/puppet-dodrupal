class dodrupal (

  # class arguments
  # ---------------
  # setup defaults

  $user = 'web',

  $version = '6.x',
  # requires php 5.4
  # $version = '7.x',
  # install latest (master branch) from repo
  # $version = 'master'

  # paths
  $repo_path = '/var/www/git/github.com',
  $target_bin = '/usr/local/zend/bin',

  # end of class arguments
  # ----------------------
  # begin class

) {


  # module doesn't work with CentOS
  #class { 'drush':
  #  ensure => latest,
  #}

  #class { 'drush::git::drush':
  #  update => true,
  #}->
  #anchor { 'drush-installed' : }

  # PEAR channel deprecated
  #pear::package { 'drush':
  #  repository => "pear.drush.org",
  #  require => Class['pear'],
  #}

  # drush now requires composer
  if ! defined(Class['composer']) {
    class { 'composer':
      auto_update => true
    }
  }

  case $version {
    default :  {
      # checkout repo and install manually
      dorepos::getrepo { 'drush' :
        user => $user,
        group => $user,
        provider => 'git',
        path => $repo_path,
        branch => $version,
        source => 'https://github.com/drush-ops/drush.git',
        # symlinkdir => "/home/${user}/",
      }->

      # make drush executable
      exec { 'drush-fromrepo-exec':
        path => '/bin:/usr/bin',
        command => "chmod u+x ${repo_path}/drush/drush",
      }->
      
      # scrub old drush if it's present
      exec { 'drush-fromrepo-scrub-old':
        path => '/bin:/usr/bin',
        command => "bash -c \"if ( test -f ${target_bin}/drush ); then rm ${target_bin}/drush; fi\"",
      }->
      
      # make a symlink into the path that deliberately overwrites old drush link (in case of upgrade)
      exec { 'drush-fromrepo-symlink':
        path => '/bin:/usr/bin',
        command => "ln -s ${repo_path}/drush/drush ${target_bin}/drush",
      }
    }
  }

}

class dodrupal (

  # class arguments
  # ---------------
  # setup defaults

  $user = 'web',

  $version = 'master',
  # DEPRECATED live - install latest from PEAR
  # DEPRECATED <version number> - install drush-<X.X.X> from PEAR 
  # master - install latest (master branch) from repo
  # e.g.
  # $version = 'drush-6.1.0.0',

  # $version_match = 'Drush Version   :  6.1',
  # used to test current version and see if we should upgrade (timesaving)

  # paths
  $repo_path = '/var/www/git/github.com',
  $target_bin = '/usr/local/zend/bin',

  # end of class arguments
  # ----------------------
  # begin class

) {

  # don't install Console_Table with PEAR because drush can't see it
  #pear::package { "Console_Table": }

  # install drush

  # doesn't work with CentOS
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

  # use first run as root to get dependencies
  #exec { 'drush-first-run' :
  #  path => "/usr/bin:/bin:${target_bin}",
  #  command => 'drush --version',
  #  user => 'root',
  #  require => [Anchor['drush-installed']],
  #}->
  # scrub drush cache
  #exec { 'drush-clear-tmp-drush' :
  #  path => '/usr/bin:/bin',
  #  command => 'rm -rf /tmp/drush*',
  #}->  
  # second run as web user to setup /tmp/drush folders with correct user
  #exec { 'drush-second-run' :
  #  path => "/usr/bin:/bin:${target_bin}",
  #  command => 'drush --version',
  #  user => $user,
  #}

  case $version {
    #'live' : {
    #  # just use whatever version comes out of the drush PEAR channel
    #}
    'master' : {
      # checkout repo and install manually
      dorepos::getrepo { 'drush' :
        user => $user,
        group => $user,
        provider => 'git',
        path => $repo_path,
        branch => 'master',
        source => 'https://github.com/drush-ops/drush.git',
        symlinkdir => "/home/${user}/",
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
    default :  {
      # for everything else try and force an upgrade to specified version
      # PEAR channel deprecated
      #exec { 'drush-upgrade-to-version' :
      #  path => "/usr/bin:/bin:${target_bin}",
      #  # redirect output to /dev/null because otherwise 'already installed' warning treated as puppet error
      #  command => "pear install drush/${version}",
      #  require => Exec['drush-first-run'],
      #  # only run the install command if we're not already got this version
      #  onlyif => "test ! `drush --version | grep -e '^\$' -e '${version_match}' -v | wc -l` == 0",
    }
  }

  # Drupal now does this automatically
  ## put an .htaccess file in /tmp as per 
  #dodrupal::tmpfiles { '/tmp' :
  #  user => $user,
  #  deny_from_all => true,
  #}
}

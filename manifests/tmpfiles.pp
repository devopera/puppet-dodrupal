define dodrupal::tmpfiles (

  # define arguments
  # ---------------
  # setup defaults

  $path = $title,
  $user = 'web',
  $group = 'www-data',
  $mode = '0640',
  $deny_from_all = false,
  
  $output_file = '.htaccess',
  $template_file = 'dodrupal/htaccess.erb',

  # end of define arguments
  # ----------------------
  # begin define

) {
  file { "dodrupal-tmpfiles-${title}" :
    path => "${path}/${output_file}",
    content => template($template_file),
    owner => $user,
    group => $group,
    mode => $mode,
  }
}

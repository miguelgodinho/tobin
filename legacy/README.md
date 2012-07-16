# Deployment:

- MySQL
  Create an empty database, and a user with full permissions on that database.
  Configure the file _family.pm_ accordingly.
  Restore a dump file (in the _bck_ dir) to the freshly created database.

- Apache

  See sample configurations for Virtual Hosts under _/conf/vhost-dev.conf_ or _/conf/vhost-prod.conf_.

- Console

  Edit and _source_ the file _/conf/env-dev.sh_ or _/conf/env-prod.sh_.

# Dependencies
## Perl Modules
   - Clone
   - Spreadsheet::WriteExcel


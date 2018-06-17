# CoRM
### Easier than a CRM
[Release Note's Link in French](https://github.com/SIGIRE/CoRM/blob/master/RELEASE_NOTES_FR.md "The CoRM's Release notes...")

## About CoRM
CoRM is a **Customer Relationship Manager** (CRM) designed for businesses about 1 to 100 collaborators. This software helps you to manage your relations between each actor that composing your environment.

CoRM does not contain inessentials functionnalities and does not have so much required fields. This software is build to help you, not to stop you during an interview or something else.

For now, CoRM is not modular and does not support the multilingual translation with *I18n*. These evolutions are in progress, so don't worry about.

## System requirement

 * Ruby 1.9.3p194
 * Rails 3.2.12

### Database adapters minimum versions supported

 * PostgreSQL with gem *pg v0.14* (preferred)
 * MySQL with gem *mysql2 v0.3.11*
 * SQLite with gem *sqlite3 v1.3.7*

## Getting started

 * Install your database manager (PostgreSQL Server for example)
 * Install Ruby and Rails (if you don't have)
 * Download/Unpack sources from git

#### Configuration

 * run 'bundle install' to add or update all gems
 * modify config/database.yml - to define your databases connections
 * for security questions, you must create a application.yml file in config's directory (example inside)

#### Preparation

Fresh install:

```
rake db:setup
```

Migration from older version:

```
rake db:migrate
```

Now, you can execute **rails s** if you're using WEBrick.

Ok, your server's running but you must create the first user, the administrator of the application.
Launch your prefered browser and goto **localhost:3000/user/new**

**Be Careful**: the length of your password must be greater than 6 !

Now, your main user is created! 
So, it's time for you to add Events type as 'incoming call' or 'outgoing call', quotations templates to create your quotation easily and quickly...

After all of that, it's time to congratulate yourself and have a coffee break.

## Licence
CoRM is under [GNU Affero Licence](http://www.gnu.org/licenses/agpl-3.0.html "GNU Affero link").

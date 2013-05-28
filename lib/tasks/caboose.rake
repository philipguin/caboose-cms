
namespace :caboose do

  desc "Initialize a caboose installation"
  task :setup => :environment do
    init_config
    init_routes
    init_assets
    init_session
    init_schema
    init_data
  end
  desc "Initializes the caboose config file"
  task :init_config => :environment do init_config end
  desc "Configures the host application to use caboose for routing"
  task :init_routes => :environment do init_routes end
  desc "Initializes all the required caboose js, css and layout files in the host application"
  task :init_assets => :environment do init_assets end  
  desc "Configures the host application to use active record session storing"
  task :init_session => :environment do init_session end
  desc "Initializes the caboose database schema"
  task :init_schema => :environment do init_schema end
  desc "Loads data into caboose tables"
  task :init_data => :environment do init_data end
  desc "Drops all caboose tables"
  task :drop_tables => :environment do drop_tables end
  desc "Creates all caboose tables"
  task :create_tables => :environment do create_tables end
 
  #=============================================================================
  
  def init_file(filename)
    gem_root = Gem::Specification.find_by_name('caboose-cms').gem_dir
    filename = Rails.root.join(filename)  
    copy_from = File.join(gem_root,'lib','sample_files', Pathname.new(filename).basename)
    
    if (!File.exists?(filename))
      FileUtils.cp(copy_from, filename)
    end  
  end
    
  def init_config
    puts "Adding the caboose initializer file..."
    init_file('config/initializers/caboose.rb')
  end

  def init_routes
    puts "Adding the caboose routes..."    
    str = "" 
    str << "\t# Catch everything with caboose\n"  
    str << "\tmount Caboose::Engine => '/'\n"
    str << "\tmatch '*path' => 'caboose/pages#show'\n"
    str << "\troot :to      => 'caboose/pages#show'\n"    
    file = File.open(Rails.root.join('config','routes.rb'), 'rb')
    contents = file.read
    file.close    
    if (contents.index(str).nil?)
      arr = contents.split('end', -1)
      str2 = arr[0] + "\n" + str + "\nend" + arr[1]
      File.open(Rails.root.join('config','routes.rb'), 'w') {|file| file.write(str2) }
    end    
  end
  
  def init_assets
    puts "Adding the javascript files..."
    init_file('app/assets/javascripts/caboose_before.js')
    init_file('app/assets/javascripts/caboose_after.js')
    
    puts "Adding the stylesheet files..."
    init_file('app/assets/stylesheets/caboose_before.css')
    init_file('app/assets/stylesheets/caboose_after.css')
    
    puts "Adding the layout files..."
    init_file('app/views/layouts/layout_default.html.erb')
  end
  
  def init_session
    puts "Setting the session config..."    
    
    lines = []
    str = File.open(Rails.root.join('config','initializers','session_store.rb')).read 
    str.gsub!(/\r\n?/, "\n")
    str.each_line do |line|
      line = '#' + line if !line.index(':cookie_store').nil?        && !line.starts_with?('#')
      line[0] = ''      if !line.index(':active_record_store').nil? && line.starts_with?('#')
      lines << line.strip
    end
    str = lines.join("\n")
    File.open(Rails.root.join('config','initializers','session_store.rb'), 'w') {|file| file.write(str) }
  end
  
  def init_schema
    drop_tables
    create_tables
  end
  
  def drop_tables
    puts "Dropping any existing caboose tables..."
    c = ActiveRecord::Base.connection  
    c.drop_table :users                if c.table_exists?('users')
    c.drop_table :roles                if c.table_exists?('roles')
    c.drop_table :permissions          if c.table_exists?('permissions')
    c.drop_table :roles_users          if c.table_exists?('roles_users')
    c.drop_table :permissions_roles    if c.table_exists?('permissions_roles')
    c.drop_table :assets               if c.table_exists?('assets')
    c.drop_table :pages                if c.table_exists?('pages')
    c.drop_table :page_permissions     if c.table_exists?('page_permissions')
    c.drop_table :sessions             if c.table_exists?('sessions')
  end

  def create_tables  
    puts "Creating required caboose tables..."
    
    c = ActiveRecord::Base.connection
    
    # User/Role/Permissions    
  	c.create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :username
      t.string :email
      t.string :password
      t.string :password_reset_id
      t.datetime :password_reset_sent
      t.string :token     
    end
    c.create_table :roles do |t|
      t.integer :parent_id
      t.string :name
      t.string :description
    end
    c.create_table :permissions do |t|
      t.string :resource
      t.string :action
    end
    
    # Role membership
    c.create_table :roles_users do |t|
      t.references :role
      t.references :user
    end
    c.add_index :roles_users, :role_id
    c.add_index :roles_users, :user_id
    
    # Role permissions    
    c.create_table :permissions_roles do |t|
			t.references :role
			t.references :permission
		end
		c.add_index :permissions_roles, :role_id
		c.add_index :permissions_roles, :permission_id
    
    # Pages and Assets
    c.create_table :assets do |t|
      t.references  :page
      t.references  :user
      t.datetime    :date_uploaded
      t.string      :name
      t.string      :filename
      t.string      :description
      t.string      :extension      
    end
    c.create_table :pages do |t|
      t.integer :parent_id
      t.string  :title
      t.string  :menu_title
      t.text    :content
      t.string  :slug
      t.string  :alias
      t.string  :uri
      t.string  :redirect_url
      t.boolean :hide, :default => false
      t.integer :content_format, :default => Caboose::Page::CONTENT_FORMAT_HTML
      t.text    :custom_css
      t.text    :custom_js
      t.string  :layout
      t.integer :sort_order, :default => 0
      t.boolean :custom_sort_children, :default => false
      t.string  :seo_title, :limit => 70
      t.string  :meta_description, :limit => 156
      t.string  :meta_robots, :default => 'index, follow' # Multi-select options: none, noindex, nofollow, nosnippet, noodp, noarchive
      t.string  :canonical_url
      t.string  :fb_description, :limit => 156
      t.string  :gp_description, :limit => 156
    end
    c.create_table :page_permissions do |t|
      t.references  :role
      t.references  :page
      t.string      :action
    end
    c.create_table :sessions do |t|
      t.string :session_id, :null => false
      t.text :data
      t.timestamps
    end
    c.add_index :sessions, :session_id
    c.add_index :sessions, :updated_at
    c.change_column :sessions, :created_at, :datetime, :null => true
    c.change_column :sessions, :updated_at, :datetime, :null => true
		
  end
  
  def init_data
    puts "Loading data into caboose tables..."
    
    admin_user = Caboose::User.create(first_name: 'Admin', last_name: 'User', username: 'admin', email: 'william@nine.is')
    admin_user.password = Digest::SHA1.hexdigest(Caboose::salt + 'caboose')
    admin_user.save
    
    admin_role  = Caboose::Role.create(parent_id: -1, name: 'Admin')
    elo_role    = Caboose::Role.create(parent_id: -1, name: 'Everyone Logged Out')
    eli_role    = Caboose::Role.create(parent_id: elo_role.id, name: 'Everyone Logged In')
    
    elo_user = Caboose::User.create(first_name: 'John', last_name: 'Doe', username: 'elo', email: 'william@nine.is')
    
    admin_perm = Caboose::Permission.create(resource: 'all', action: 'all')
    Caboose::Permission.create(resource: 'users'	      , action: 'view')
    Caboose::Permission.create(resource: 'users'	      , action: 'edit')
    Caboose::Permission.create(resource: 'users'	      , action: 'delete')
    Caboose::Permission.create(resource: 'users'	      , action: 'add')
    Caboose::Permission.create(resource: 'roles'	      , action: 'view')
    Caboose::Permission.create(resource: 'roles'	      , action: 'edit')
    Caboose::Permission.create(resource: 'roles'	      , action: 'delete')
    Caboose::Permission.create(resource: 'roles'	      , action: 'add')
    Caboose::Permission.create(resource: 'permissions'	, action: 'view')
    Caboose::Permission.create(resource: 'permissions'	, action: 'edit')
    Caboose::Permission.create(resource: 'permissions'	, action: 'delete')
    Caboose::Permission.create(resource: 'permissions'	, action: 'add')

    # Add the admin user to the admin role
    admin_user.roles.push(admin_role)
    admin_user.save
    
    # Add the elo to the elo role
    elo_user.roles.push(elo_role)
    elo_user.save

    # Add the all/all permission to the admin role
    admin_role.permissions.push(admin_perm)
    admin_role.save
    
    # Create the home page
    home_page  = Caboose::Page.create(title: 'Home'  , parent_id: -1, hide: 0, layout: 'home'   , uri: '')
    admin_page = Caboose::Page.create(title: 'Admin' , parent_id: home_page.id, hide: 0, layout: 'admin', alias: 'admin', slug: 'admin', uri: 'admin')
    login_page = Caboose::Page.create(title: 'Login' , parent_id: home_page.id, hide: 0, layout: 'login', alias: 'login', slug: 'login', uri: 'login')
    Caboose::PagePermission.create(role_id: elo_role.id, page_id: home_page.id, action: 'view') 
    Caboose::PagePermission.create(role_id: elo_role.id, page_id: login_page.id, action: 'view')
    
  end
end
# encoding: utf-8

##
# Controller that manage Account
#
class AccountsController < ApplicationController
  load_and_authorize_resource
  before_filter :check_can_read!, only: [:show]

  has_scope :by_company_like, as: :company
  has_scope :by_contact_full_name_like, as: :contact
  has_scope :by_tel, as: :phone
  has_scope :active, type: :boolean, default: true
  has_scope :inactive, type: :boolean
  has_scope :by_account_category, as: :account_category
  has_scope :by_origin, as: :origin
  has_scope :by_tags, as: :tag
  has_scope :by_import_id, as: :import_id
  has_scope :by_account_tag, as: :account_tag
  has_scope :by_zip, as: :zip
  has_scope :by_user, as: :user
  has_scope :by_activity, as: :activity

  ##
  # Show the full list of Accounts by paginate_by

  def index
    @accounts = apply_scopes(Account).order("company")

    #ClickToCall
    @setting = Setting.all.first
    #creation des ensembles contenant les comptes et contacts pour l'utilisation du typeahead
    @autocomplete_accounts = Account.find(:all,:select=>'company').map(&:company) #societe
    @autocomplete_contacts = Contact.find(:all,:select=>'surname').map(&:surname) #nom

    flash.now[:alert] = "Pas de comptes !" if @accounts.empty?

    respond_to do |format|
      format.html { @accounts = @accounts.page(params[:page]) }
      format.json { render :json => @accounts }
    end
  end

  def extract
    @accounts = apply_scopes(Account).
                order("company")

    flash.now[:alert] = "Pas de comptes !" if @accounts.empty?

    respond_to do |format|
      format.html { @accounts = @accounts.page(params[:page]) }
      format.csv { render :text => @accounts.to_csv }
      format.xlsx
    end
  end

  ##
  # Show events of an account

  def show
    @account = Account.find(params[:id])
    respond_to do |format|
      format.html { render :layout => 'account_show' }
      format.json { render :json => @account }
    end
  end

  ##
  # Render a page with a form to create a new Account
  #
  # GET /accounts/new
  # GET /accounts/new.json
  def new
    @account = Account.new
    @account.user = current_user
    @account.account_category_id = Account.default_account_category_id
    @users = User.all_reals
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @account }
    end
  end

  ##
  # Render a page to edit one occurence of Account
  #
  # GET /accounts/1/edit
  def edit
    @account = Account.find(params[:id])
    @users = User.all_reals
  end

  ##
  # Save an instance of Account to the DB
  #exception.message
  # POST /accounts
  # POST /accounts.json
  def create
    @account = Account.new(params[:account])
    @account.created_by = current_user.id
    @account.company = @account.uppercase_company
    @account.web = Format.to_url(@account.web)
    if params[:display_account_tag].nil?
      @account.tags.clear
    else
      tag = Tag.find(params[:display_account_tag])
      @account.tags.clear
      @account.tags << tag #unless @compte.produits.exists?(produit)
    end

    respond_to do |format|
      if @account.save
        format.html { redirect_to account_events_url(@account.id), :notice => 'Le compte a été créé.' }
        format.json { render :json => @account, :status => :created, :location => @account }
      else
        flash[:error] = t('app.save_undefined_error')
        format.html { render :action => "new" }
        format.json { render :json => @account.errors, :status => :unprocessable_entity }
      end
    end
  end

  ##
  # Save an instance of Account which already exists
  #
  # PUT /accounts/1
  # PUT /accounts/1.json
  def update
    @account = Account.find(params[:id])
    @account.modified_by = current_user.id
    params[:account][:company] = UnicodeUtils.upcase(params[:account][:company], I18n.locale)
    params[:account][:web] = Format.to_url(params[:account][:web])
    if params[:display_account_tag].nil?
      @account.tags.clear
    else
      tag = Tag.find(params[:display_account_tag])
      @account.tags.clear
      @account.tags << tag
    end

    respond_to do |format|
      if @account.update_attributes(params[:account])
        format.html { redirect_to account_events_url(@account.id), :notice => 'Le compte a été mis à jour.' }
        format.json { head :no_content }
      else
        flash[:error] = t('app.save_undefined_error')
        format.html { render :action => "edit" }
        format.json { render :json => @account.errors, :status => :unprocessable_entity }
      end
    end
  end

  ##
  # Delete an Account stored into the DB
  #
  # DELETE /accounts/1
  # DELETE /accounts/1.json
  def destroy
    @account = Account.find(params[:id])
    @account.destroy

    respond_to do |format|
      format.html { redirect_to root_path, :notice => "Le compte a bien été supprimé."  }
      format.json { head :no_content }
    end
  end

  ##
  # Called by the main search bar
  # search?account=[xxx]
  #
  def search

    #ClickToCall
    @setting = Setting.all.first

    if !params.nil? and !params[:account].nil?
      company = UnicodeUtils.upcase(params[:account].strip.concat("%"))
      if params[:format] and params[:format] != 'html' then
        @elements = Array.new
        # You can put the contact url edit pattern here, to redirect when a conctact will be selected in typeahead
        @elements.push({ :type => 'info', 'account_url' => '/compte/[:id]/evenements', 'contact_url' => '/compte/[:account_id]/evenements', 'contact_url_default' => '/contact/[:id]/edit' })
        Account.where('company LIKE ? OR company LIKE ?', company, '%'.concat(company)).select('id, company AS name').each {|e|
          @elements.push({ :id => e.id, :name => e.name, :type => 'account' })
        }
        if (!params[:contacts].nil? and params[:contacts] == 'true')
          Contact.where('surname LIKE ? OR forename LIKE ?', company, company).select('id, title, forename, surname, account_id').limit(10).each {|e|
            @elements.push({ :id => e.id, :name => e.full_name, :account_id => e.account_id, :type => 'contact' })
          }
        end
        @response = @elements
      else
        @accounts = Account.where('company LIKE ?', company).page(params[:page]).per(25)
      end
      respond_to do |format|
        format.html { render :action => :index }
        format.json { render :json => @elements }
      end
    end
  end

  ##
  # Add a Tag to an Account
  #
  def add_tag
    if @ability.can? :update, Account
      @tag = Tag.find(params[:tag_id])
      @account = Account.find(params[:account_id])
      @account.tags << @tag
      redirect_to account_tags_url(@account.id), :notice => "Affectation du tag effectuée."
    else
      flash[:error] = t('app.cancan.messages.unauthorized').gsub('[action]', t('app.actions.update')).gsub('[undefined_article]', t('app.default.undefine_article_male')).gsub('[model]', t('app.controllers.Account'))
      redirect_to accounts_url
      return false
    end
  end

  ##
  # Remove a Tag from an Account
  #
  def delete_tag
    if @ability.can? :update, Account
      @tag = Tag.find(params[:tag_id])
      @account = Account.find(params[:account_id])
      @account.tags.delete(@tag)

      respond_to do |format|
          format.html  { redirect_to account_tags_url(@account.id), :notice => "Suppression de l'affectation du tag effectuée." }
          format.json  { render :json => @tag }
      end
    else
      flash[:error] = t('app.cancan.messages.unauthorized').gsub('[action]', t('app.actions.update')).gsub('[undefined_article]', t('app.default.undefine_article_male')).gsub('[model]', t('app.controllers.Account'))
      redirect_to accounts_url
      return false
    end
  end


  def duplicates
    @accounts_pairs = [] # array of hashes
    Account.order(:id).each do |account|
      if ( !(account.tel.blank?)  and !(@accounts_pairs.find {|a| a[0] == account or a[1] == account}) )
        duplicates = Account.duplicate_phone(account.tel, account.id)
          if !(duplicates.blank?)
            @accounts_pairs << [account, duplicates.first]
          end
      end
    end
  end

  def merge
    if ((@ability.can? :update, Account) and (@ability.can? :destroy, Account))
      account1 = Account.find(params[:id])
      account2 = Account.find(params[:id_to_merge])
      account1.merge(account2.id)
    else
      flash[:error] = t('app.cancan.messages.unauthorized').gsub('[action]', t('app.actions.destroy')).gsub('[undefined_article]', t('app.default.undefine_article_male')).gsub('[model]', t('app.controllers.Account'))
    end

    redirect_to duplicate_accounts_path
  end


  private
  def check_can_read!
    unless @ability.can? :read, Account
      flash[:error] = t('app.cancan.messages.unauthorized').
        gsub('[action]', t('app.actions.show')).
        gsub('[undefined_article]', t('app.default.undefine_article_male')).
        gsub('[model]', t('app.controllers.Account'))
      redirect_to :back
      return false
    end
  end
end

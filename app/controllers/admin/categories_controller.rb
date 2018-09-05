class Admin::CategoriesController < Admin::BaseController
  before_action :load_categories, only: %i[new create]
  before_action :find_category, except: %i[index new create show_import import delete_more_cat]
  before_action :all_categories_without_self, only: %i[edit update]

  def index
    @categories_no_parent = Category.where(parent_id: nil)
    if params[:content].blank?
      @categories = Category.where(status: 'selling').paginate(page: params[:page], per_page: 10).order('id DESC')
    else
      @categories = Category.search_name(params[:content]).where(status: 'selling').paginate(page: params[:page], per_page: 10).order('id DESC')
    end
  end

  def new
    @parent_id = params[:format] unless params[:format].nil?
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    @category.status = "selling"
    if @category.save
      flash[:success] = 'Add category success'
      redirect_to admin_categories_path
    else
      render :new
    end
  end

  def edit
    @parent_id = @category.parent_id
  end

  def update
    if @category.update_attributes(category_params)
      flash[:success] = 'Update success'
      redirect_to admin_categories_path
    else
      render :edit
    end
  end

  def destroy
    if check_delete_category @category
      update_category_chid @category
      flash[:success] = 'Category deleted'
    else
      flash[:success] = 'Delete error'
    end
    redirect_to admin_categories_url
  end

  def import
    if params[:file].nil?
      flash[:notice] = 'Please choose file'
      render :show_import
    else
      if Category.import_file params[:file]
        flash[:notice] = 'Data imported'
      else
        flash[:danger] = 'Import error'
      end
      redirect_to admin_categories_path
    end
  end

  def delete_more_cat
    if request.post?
      if params[:ids]
        delete_ids = []
        params[:ids].each do |id|
          if check_delete_category Category.find(id.to_i)
            delete_ids << id.to_i
          else
            redirect_to admin_categories_path, notice: 'Delete error'
          end
        end
        unless delete_ids.empty?
          delete_ids.each do |id|
            update_category_chid @category
          end
          redirect_to admin_categories_path, notice: 'Delete success'
        end
      end
    end
  end

  private

    def category_params
      params.require(:category).permit(:name, :parent_id)
    end

    def load_categories
      @categories = Category.all
    end

    def find_category
      @category = Category.find_by(id: params[:id])
      redirect_to '/404' unless @category
    end

    def all_categories_without_self
      @categories = Category.get_without_self(@category.id).get_without_parent_self(@category.id)
    end

    def check_delete_category(category)
      category.products.each do |product|
        return false unless product_can_delete product
      end
      check_delete_category category.childcategories if category.childcategories.any?
      true
    end

    def product_can_delete(product)
      if !product.timers.where(status: 'on').empty?
        return false
      else
        Item.where(product_id: product.id).each do |item|
          if item.order.status != 'received'
            return false
          end
        end
      end
      true
    end

    def update_category_chid category
      category.update_attribute(:status, 'unselling')
      category.products.each do |product|
        product.update_attribute(:status, 'unselling')
      end
      update_category_chid category.childcategories if category.childcategories.any?
      true
    end
end

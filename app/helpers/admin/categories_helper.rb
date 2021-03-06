module Admin::CategoriesHelper
  def parent_name(id)
    Category.find_by(id: id).name
  end

  def tree_list(categories)
    content_tag(:ul) do
      categories.each do |category|
        if category.childcategories.any?
          concat(
            content_tag(:li, id: category.id) do
              concat(category.name)
              concat(tree_list(category.childcategories))
            end
          )
        else
          concat(content_tag(:li, category.name, id: category.id))
        end
      end
    end
  end
end

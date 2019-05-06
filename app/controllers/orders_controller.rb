class OrdersController < ApplicationController
  before_action :find_order, only: %i[index edit update destroy]

  def index
    @items = @order.items if @order
  end

  def destroy
    item = Item.find_by(id: params[:id])
    total = @order.total_price - item.amount
    product = item.product
    product.update_attribute(:quantity, quantity)
    if item.destroy
      product.timers.each do |timer|
        obj_timer = JSON.parse($redis.get(timer.id))
        obj_timer['product_quantity'] += 1
        $redis.set(timer.id, obj_timer.to_json)
      end
      _quantity = product.quantity + 1
      @order.update_attribute(:total_price, total)
      @order.destroy unless @order.items.any?
      flash[:success] = 'Delete success'
    else
      flash[:danger] = 'Delete error'
    end
    redirect_to user_orders_path
  end

  def edit
    @items    = @order.items if @order
    @payments = Payment.all
  end

  def update
    if @order.update_attributes(order_params)
      total = @order.total_price + 29000
      @order.update_attributes(status: 'checkouted', total_price: total)
      redirect_to root_path, success: 'Success'
    else
      render :edit
    end
  end

  private

    def order_params
      params.require(:order).permit(%i[name address phone type_payment])
    end

    def find_order
      @order = Order.find_by(user_id: current_user.id, status: Order::STATUS_WAITTING)
    end
end

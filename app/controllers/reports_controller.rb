class ReportsController < ApplicationController
  before_filter :authenticate_user!
  authorize_resource :class=>false
  def payments_due
    @suppliers=Supplier.all

  end
  def internal_orders
 @internal_orders =  InternalOrder.find(:all,:conditions=>{:status=>0})
 render :layout=>false
end
def updateorder
   @internal_orders =  InternalOrder.find(params[:id])
 
   @internal_orders.update_attributes(:status=>1)
  
  redirect_to :action=>'internal_orders'
end
def update_all_order
  @internal_orders =  InternalOrder.all
  @internal_orders.each do|i|
    i.update_attributes(:status=>1)
  end
  render :text=> "Sucessfully Delivered"
end
end

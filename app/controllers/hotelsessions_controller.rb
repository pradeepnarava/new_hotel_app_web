class HotelsessionsController < ApplicationController
  #authorize_resource :class=>false
  before_filter :authenticate_user!
  layout 'show', :only=>['show','billing']
  #before_filter :authenticate_user!,:only=>['show','billing','dashboard']
  require 'gchart'

  #api
  
  def create
    
    if request.post?
      puts"======1========"
      puts params.inspect
      @item_names=params[:items][:id].split(",")
      @quantities=params[:items][:quantity].split(",")
      @no_of_items=(0..@item_names.size-1)
      puts "======2====="
      @customer=Customer.find_by_table_id(params[:table_id],:conditions=>{:status=>0})
      puts"=====3===="
      @customer=Customer.new(:table_id=>params[:table_id]) if @customer.nil?
      @order=Order.create(:total=>params[:total])
      
      puts "=============="
      puts @no_of_items
    
      @no_of_items.each do|i|

        puts @order.id
        Orderlist.create(:item_id=>@item_names[i],:order_id=>@order.id,:quantity=>@quantities[i],:price=>(Item.find(@item_names[i])).price)
      end
     
      
      @customer.orders<<@order
      if !@customer.save
        puts "========"
        @order.destroy
      end

      #      puts "================="
      #      puts params.inspect
      #      params[:items].each do |k,v|
      #        puts "================="
      #      puts v
      #        //@hotelsession.items<<Item.create(v)
      #      end
      respond_to do|format|

        if !@order.nil?

          format.html
          format.json {render :json=>@order }
          format.xml{render :xml=>@order}
        else
          format.html
          format.json {render :json=>nil}
          format.xml{render :xml=>nil}
        end
      end
    end
  end


  #destroy..........
  def destroy
    @hotelsession=Hotelsession.find(params[:table_name])
    @hotelsession.destroy
  end

  #Display at kitchen..........
  def show
    
    @orders=Order.find(:all, :limit => 20,:conditions=>{:status=>0},:order=>'created_at DESC')
    @orders=@orders.each_slice(10).to_a
    
  end
  def show_nolayout

    @orders=Order.find(:all, :limit => 20,:conditions=>{:status=>0},:order=>'created_at DESC')
    @orders=@orders.each_slice(10).to_a
     
    render 'show',:layout=>false
  end


  #billing........
  def billing

    @orders=Order.find(:all,:order=>'created_at DESC',:conditions=>{:status=>1})
    @customers=Customer.find(:all,:order=>'updated_at DESC',:conditions=>{:status=>1})
authorize! :billing, [@orders, @customers]
  end
  def billing_nolayout

    @orders=Order.find(:all,:order=>'created_at DESC',:conditions=>{:status=>1})
    @customers=Customer.find(:all,:order=>'updated_at DESC',:conditions=>{:status=>1})
    authorize! :billing, [@orders, @customers]
    render 'billing',:layout=>false

  end

  #delivered from kitchen
  def delivered
    puts "================================"
    p params.inspect
    puts "================================"
    @order=Order.find(params[:id])
    @order.status=1
    @order.save
    # redirect_to :action=>"show"
  end


  #check out
  #192.168.2.15:3000/hotelsessions/checkout.json,{:table_id=>7}
  def checkout
    @customer=Customer.find_by_table_id(params[:table_id],:conditions=>{:status=>0})
    @pending_count=@customer.orders.count(:conditions=>{:status=>0})
    puts @pending_count
    @total=@customer.orders.sum(:total)
    if @pending_count==0
      @customer.update_attributes(:status=>1,:total=>@total)
      @customer.orders.each do|ord|
        ord.update_attributes(:status=>2)
      end
      @t={:bill=>@total}
    else
      @t={:bill=>nil}
    end
    respond_to do|format|
      format.html {redirect_to :action=>"billing"}
      format.json {render :json=>@t }
      format.xml{render :xml=>@t}
    end
  end


  # if paid
  def paid
    #render :text=>'hello'
    @customer=Customer.find(params[:id])
    @customer.update_attributes(:status=>2)
    redirect_to :action=>"billing"
  end



  #Recall
  #'',{:table_id=>5}

  def recall_order
    @customer=Customer.find_by_table_id_and_status(params[:table_id],[0,1])
    #puts @customer.inspect
    @i=[]
    if !@customer.nil?
      # puts "====================="
      (@customer.orders).each do|x|
       
        @i<< x.orderlists
      end
      @h={:items=>@i.flatten}
      #puts @h
    end
    respond_to do|format|

      if !@customer.nil?


        format.json {render :json=>@h}
        format.xml{render :xml=>@h}
      else

        format.json {render :json=>nil}
        format.xml{render :xml=>nil}
      end
    end
  end



  #    def update_order
  #
  #
  #      @item_names=params[:items][:item_name].split(",")
  #      @prices=params[:items][:price].split(",")
  #      @quantities=params[:items][:quantity].split(",")
  #      @categories=params[:items][:category].split(",")
  #      @no_of_items=(0..@item_names.size-1)
  #      @hotelsession=Hotelsession.find(params[:id])
  #
  #      @hotelsession.total=@hotelsession.total+params[:total].to_i
  #      puts @item_names.inspect
  #      puts @prices.inspect
  #      @no_of_items.each do|i|
  #        @hotelsession.items<<I.create(:item_name=>@item_names[i],:price=>@prices[i],:quantity=>@quantities[i],:price=>(Item.find(@item_names[i])).price)
  #      end
  #
  #      #      puts "================="
  #      #      puts params.inspect
  #      #      params[:items].each do |k,v|
  #      #        puts "================="
  #      #      puts v
  #      #        //@hotelsession.items<<Item.create(v)
  #      #      end
  #      respond_to do|format|
  #        if @hotelsession.save
  #
  #          format.html
  #          format.json {render :json=>@hotelsession }
  #          format.xml{render :xml=>@hotelsession}
  #        else
  #          format.html
  #          format.json {render :json=>nil}
  #          format.xml{render :xml=>nil}
  #        end
  #      end
  #    end





  def dashboard
    if current_user.has_role? :admin or current_user.has_role? :manager or  current_user.has_role?:moderator
    @customers=Customer.find(:all,:order=>'updated_at DESC',:conditions=>{:status=>2,:date_of_transcation=>Date.today})
    if params.key?(:sorting)
      if params[:sorting][:start_date].empty? or params[:sorting][:end_date].empty?
        flash[:error]= 'Dates should not be empty!'
        redirect_to :controller => 'hotelsessions', :action => 'dashboard'
      else
      @sd = Date.parse( params[:sorting][:start_date].split('-').reverse!.join('-'))
      @ed = Date.parse( params[:sorting][:end_date].split('-').reverse!.join('-'))
      if @sd > @ed
        flash[:error] = 'Oops! Start Date should not be erlier than end date. Please try again!'
      else
#     @sd=Date.parse( params[:sorting][:start_date].to_a.sort.collect{|c| c[1]}.join("-") )
#     @ed=Date.parse( params[:sorting][:end_date].to_a.sort.collect{|c| c[1]}.join("-") )
      @sorted_customers=Customer.find(:all,:order=>'updated_at DESC',:conditions=>{:status=>2,:date_of_transcation=>[@sd..@ed]})
      end
      end
      #     respond_to do |format|
      #  format.html # show.html.erb
      #  #format.pdf { render :text => PDFKit.new( sales ).to_pdf }
      #end
    end
    #      respond_to do|format|
    #format.pdf do
    #        render :pdf => "dashboard"
    #      end
    #        end
    else
       verify
    end
  end
  
  def receipt
    @customer=Customer.find(params[:id])
    @orders=@customer.orders
    render 'receipt', :layout=>false
  end

  def tax
    if request.post?
      @users=User.all
      @users.each do |u|
        u.update_attributes(:tax=>params[:tax])
        respond_to do|format|

        end
      end
    end
    return
  end

  def adjustTotal
    puts "==========================="
    @customer=Customer.find(params[:id])
  end
  #    pdf = kit.to_pdf
  #    file = kit.to_file('desktop')
  #render 'adjust_total'
  
  def update_total
    @customer=Customer.find(params[:id])
    t=@customer.total
    @customer.update_attributes(:adjusted_total=>t,:total=>params[:adjusted_total],:adjustment_reason=>params[:adjustment_reason])
    redirect_to :action=>'billing'
  end
  #  def sales_pdf
  #
  #    @sd=params[:start_date]
  #    @ed=params[:end_date]
  #    @sorted_customers=Customer.find(:all,:order=>'updated_at DESC',:conditions=>{:status=>2,:date_of_transcation=>[@sd..@ed]})
  #    #@sorted_customers=params[:id]
  #    #    respond_to do|format|
  #    #PDFKit.new(sales, :page_size => 'Letter')
  #    #    #pdf = kit.to_pdf
  #    #    end
  #
  #    respond_to do |format|
  #      format.html # show.html.erb
  #      format.pdf { render :text => PDFKit.new( sales ).to_pdf }
  #    end
  #  end
  def sales
    @sd=params[:start_date]
    @ed=params[:end_date]
   
    @sorted_customers=Customer.find(:all,:order=>'updated_at DESC',:conditions=>{:status=>2,:date_of_transcation=>[@sd..@ed]})
    render 'sales', :layout=>false
    #return
  end
  def inventory
    @stcs=[]
    if params.key?(:sorting)
      if params[:sorting][:start_date].empty? or params[:sorting][:end_date].empty?
        flash[:error]= 'Dates should not be empty!'
        redirect_to :controller => 'hotelsessions', :action => 'inventory'
      else
      @sd = Date.parse( params[:sorting][:start_date].split('-').reverse!.join('-'))
      @ed = Date.parse( params[:sorting][:end_date].split('-').reverse!.join('-'))
      if @sd > @ed
        flash[:error] = 'Oops! Start Date should not be erlier than end date. Please try again!'
      else
#      @sd = Date.parse(params[:sorting][:start_date].split('-').reverse!.join('-'))
#      @ed = Date.parse(params[:sorting][:end_date].split('-').reverse!.join('-'))
#      #@sd=Date.parse( params[:sorting][:start_date].to_a.sort.collect{|c| c[1]}.join("-") )
#      #@ed=Date.parse( params[:sorting][:end_date].to_a.sort.collect{|c| c[1]}.join("-") )
      @sorted_customers=Customer.find(:all,:order=>'updated_at DESC',:conditions=>{:status=>2,:date_of_transcation=>[@sd..@ed]})
      @stcs=StockCount.find(:all,:conditions=>{:created_at=>(@sd..@ed)})
      end
      end
          #puts "----1--"
      #puts @stcs.inspect
      # puts "----1--"
      if !@stcs.empty?
        last=StockCount.find(:last,:conditions=>['created_at <?',@sd])
        #puts"--------2-----"
        #puts last
      if last.nil?
        last=Delivery.find(:first)
        @cost_brought_forward=0
      else
        @cost_brought_forward=last.cost
      end
      #puts last
      #puts"--------2-----"
      @stcs.unshift(last) 
      @stcs_size=@stcs.size
      @stlis=StockListItem.all
       end
    end
    #authorize! :inventory, @stlis
  end
  def inventory_pdf

    if params.key?(:sorting)


      @sd=Date.parse( params[:sorting][:start_date].to_a.sort.collect{|c| c[1]}.join("-") )
      @ed=Date.parse( params[:sorting][:end_date].to_a.sort.collect{|c| c[1]}.join("-") )
      #@sorted_customers=Customer.find(:all,:order=>'updated_at DESC',:conditions=>{:status=>2,:date_of_transcation=>[@sd..@ed]})


    end
    #authorize! :inventory, @stlis
    render 'inventory_pdf'
  end
  def day_report
    @customers=Customer.find(:all,:order=>'updated_at DESC',:conditions=>{:status=>2,:date_of_transcation=>Date.today})
    @items=Item.all
  end
  def check_inventory
    
  end

end


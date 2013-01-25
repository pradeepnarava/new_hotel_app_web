ActiveAdmin.register User do
  form do |f|
    f.inputs "Users" do
      f.input :email
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end 
end

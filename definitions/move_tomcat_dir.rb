define :move_tomcat_dir, :dir_in_home => "", :dir_target => "" do
    # the definition move a tomcat directory from a stadard params[:dir_in_home] place to some alternative
    # params[:dir_target] place creating a compatibility symlinks
    # execute only if both paths defined
    if ! ( params[:dir_in_home].empty? || params[:dir_target].empty? )
        # ensure the target place exists and create an empty one there
        directory params[:dir_target] do
            action :create
            owner node[:tomcat6][:user]
            group node[:tomcat6][:group]
            recursive true
        end
        # move the directory
        ruby_block "move-dir" do
            block do
                File.rename(params[:dir_in_home], params[:dir_target])
            end
            action :create
        end
        # compatability link
        link params[:dir_in_home] do
            to params[:dir_target]
            action :create
        end
    end
end

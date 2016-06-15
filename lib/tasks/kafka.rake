namespace :kafka do
  namespace :offset do
    desc <<-EOF
      Get the current offset.
    EOF
    task :get, [:client_id, :group, :topic, :partition] => :environment do |t,args|
      [:client_id,:group, :topic, :partition].each do |p|
        raise "No #{p} given" if args[p].blank?
      end

      consumer = $kafka[args[:client_id]].consumer(:group_id => args[:group])
      consumer.subscribe(args[:topic])
      consumer.send(:join_group)
      om = consumer.instance_variable_get("@offset_manager")
      puts om.next_offset_for(args[:topic], args[:partition].to_i)

    end

    desc <<-EOF
      Set the current offset.
    EOF
    task :set, [:client_id, :group, :topic, :partition, :offset] => :environment do |t,args|
      [:client_id,:group, :topic, :partition, :offset].each do |p|
        raise "No #{p} given" if args[p].blank?
      end

      consumer = $kafka[args[:client_id]].consumer(:group_id => args[:group])
      consumer.subscribe(args[:topic])
      consumer.send(:join_group)
      om = consumer.instance_variable_get("@offset_manager")
      om.mark_as_processed(args[:topic], args[:partition].to_i,
                           args[:offset].to_i)
      puts om.commit_offsets
    end
  end
end

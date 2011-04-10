shared_examples_for "uses attribute map" do
  

  context "#self.map_attribute" do

    before do
      @class = Class.new(subject) do
        map :name => 'C_Name', :id => 'ContactID'
      end
    end

    it 'should return value in attribute_map when given a key exists' do
      @class.map_attribute(:name).should == :C_Name
    end

    it 'should return given value when key does not exist within attribute_map' do
      @class.map_attribute(:Cezar).should == 'Cezar'
    end

  end

  context "#self.attribute_map" do
    specify { subject.attribute_map.class == Hash }

    context "when inherited entity attribute map is cloned by not the same object" do
      before do
        @super = Class.new(subject)
        @super.attribute_map[:id] = 'ContactID'
        @child = Class.new(@super)
      end

      it 'should have all the same keys' do
        @child.attribute_map.keys.should == @super.attribute_map.keys 
      end

      it 'should have all the same values' do
        @child.attribute_map.values.should == @super.attribute_map.values
      end

      it 'should not be the same object as parent' do
        @child.attribute_map.object_id.should_not === @super.attribute_map.object_id
      end

    end
    
  end
  
  
  context "#self.map" do

    before do
      @class = Class.new(Eloqua::Entity) do
        self.entity_type = 'Contact'
      end      
    end

    it 'should be able to use map on the class level to map attributes' do
      @class.map :id => 'C_Attribute'
      @class.attribute_map[:id].should == :C_Attribute
    end

    it 'should be able to override existing maps' do
      @class.map :id => 'not_me'
      @class.map :id => 'me'
      @class.attribute_map[:id].should == :me
    end
    
    context 'when reverse' do
      it 'should also add the reverse to attribute_map_reverse' do
        @class.map :Contact => 'name'
        @class.map :IDC => 'id', :Real => 'email'

        reverse = {
          :name => :Contact,
          :id => :IDC,
          :email => :Real
        }.with_indifferent_access
        @class.attribute_map_reverse.should == reverse
      end
    end

  end  
  
  context "#map_attributes" do

     let(:input) do
       {
           :C_EmailAddress => 'email@address.com',
           :ContactID => '1',
           :normal_id => 'wow'
       }.with_indifferent_access
     end

     let(:expected) do
       {
           :email_address => 'email@address.com',
           :id => '1',
           :normal_id => 'wow'
       }.with_indifferent_access
     end

     let(:reverse) do
       {
         :email_address => 'C_EmailAddress',
         :id => 'ContactID',
         :normal_id => 'normal_id'
       }.with_indifferent_access
     end

     before do
       klass_object = Class.new(subject) do
         map :ContactID => 'id'
       end
       @klass = klass_object.new
       @result = @klass.send(:map_attributes, input)
     end

     it 'should map attributes from CamelCase format to snake_case format' do
       @result.should == expected
     end

     it 'should store the original key names in attribute_keys_to_eloqua' do
       @klass.instance_reverse_keys.should == reverse
     end

     context "#reverse_map_attributes" do

       before do
         @reversed = @klass.send(:reverse_map_attributes, @result)
       end

       it 'should be able to reverse map_attributes back into input' do
         @reversed.should == input  
       end

     end

   end
  
end
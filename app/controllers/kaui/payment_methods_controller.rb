class Kaui::PaymentMethodsController < Kaui::EngineController

  def new
    @payment_method = Kaui::PaymentMethod.new(:account_id  => params[:account_id],
                                              :plugin_name => params[:plugin_name] || Kaui.creditcard_plugin_name.call)
  end

  def create
    @payment_method             = Kaui::PaymentMethod.new(params[:payment_method].delete_if { |key, value| value.blank? })
    # Transform "1" into boolean
    @payment_method.is_default  = @payment_method.is_default == '1'
    # Sensible default
    @payment_method.plugin_name ||= Kaui.creditcard_plugin_name.call

    # Instance variables needed in case of failure
    @card_type                  = params[:card_type]
    @card_holder_name           = params[:card_holder_name]
    @expiration_year            = params[:expiration_year]
    @expiration_month           = params[:expiration_month]
    @credit_card_number         = params[:credit_card_number]
    @verification_value         = params[:verification_value]
    @address1                   = params[:address1]
    @address2                   = params[:address2]
    @city                       = params[:city]
    @postal_code                = params[:postal_code]
    @state                      = params[:state]
    @country                    = params[:country]

    # Magic from lib/killbill/helpers/active_merchant/payment_plugin.rb
    @payment_method.plugin_info = {
        'type'                => 'CreditCard',
        'ccType'              => @card_type,
        'ccFirstName'         => @card_holder_name,
        'ccLastName'          => @card_holder_name,
        'ccExpirationMonth'   => @expiration_month,
        'ccExpirationYear'    => @expiration_year,
        'ccNumber'            => @credit_card_number,
        'ccVerificationValue' => @verification_value,
        'address1'            => @address1,
        'address2'            => @address2,
        'city'                => @city,
        'country'             => @country,
        'zip'                 => @postal_code,
        'state'               => @state
    }

    @plugin_properties = params[:plugin_properties].values.select{ |item| !(item['value'].blank? || item['key'].blank?) } unless params[:plugin_properties].blank?
    @plugin_properties.map! do |property|
      KillBillClient::Model::PluginPropertyAttributes.new(property)
    end unless @plugin_properties.blank?

    begin
      @payment_method = @payment_method.create(@payment_method.is_default, current_user.kb_username, params[:reason], params[:comment],
                                               @plugin_properties.blank? ? options_for_klient : ({:pluginProperty => @plugin_properties}).merge(options_for_klient))
      redirect_to kaui_engine.account_path(@payment_method.account_id), :notice => 'Payment method was successfully created'
    rescue => e
      flash.now[:error] = "Error while creating payment method: #{as_string(e)}"
      render :action => :new
    end
  end

  def destroy
    payment_method_id = params[:id]

    payment_method = Kaui::PaymentMethod.find_by_id(payment_method_id, false, options_for_klient)
    begin
      Kaui::PaymentMethod.destroy(payment_method_id, params[:set_auto_pay_off], false, current_user.kb_username, params[:reason], params[:comment], options_for_klient)
      redirect_to kaui_engine.account_path(payment_method.account_id), :notice => "Payment method #{payment_method_id} successfully deleted"
    rescue => e
      flash[:error] = "Error while deleting payment method #{payment_method_id}: #{as_string(e)}"
      redirect_to kaui_engine.account_path(payment_method.account_id)
    end
  end

  def show
    restful_show
  end

  def restful_show
    payment_method = Kaui::PaymentMethod.find_by_id(params.require(:id), false, options_for_klient)
    redirect_to kaui_engine.account_path(payment_method.account_id)
  end

  def validate_external_key
    external_key = params.require(:external_key)

    begin
      payment_methods = Kaui::PaymentMethod::find_by_external_key(external_key,false,false,'NONE', options_for_klient)
    rescue KillBillClient::API::NotFound
      payment_methods = nil
    end

    render json: {:is_found => !payment_methods.nil?}

  end

  private

  def find_value_from_properties(properties, key)
    return nil if key.nil? or properties.nil?
    prop = (properties.find { |kv| kv.key.to_s == key.to_s })
    prop.nil? ? nil : prop.value
  end
end

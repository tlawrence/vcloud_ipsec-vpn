require "vpnconfig/version"

module Vpnconfig
  class API
    # TODO: When this is actually doing the API call as well should be able to stop saving the xml file and just return it instead


    def read_edgegw_config(dc, conn)
      puts 'Getting details of dcs'
      edgegw_overviews = get_edgegw_overviews(dc, conn)
      puts 'Getting details of edge gateways'
      edgegw_details = get_edgegw_details(edgegw_overviews, dc, conn)
      #Get edge gateway config
      puts 'Getting config of edge gateways'
      edgegw_configs = get_edgegw_configs(edgegw_details, dc, conn)
      edgegw_configs
    end

    def post_to_api(xml)
      puts 'About to post some stuff to the API....'
      puts xml
    end

    def get_edgegw_configs(edgegw_details, dc, conn)
      href = edgegw_details.at('EdgeGatewayRecord')['href']
      get_xml_object(href, conn["auth_token"], 'EdgeGateway').at('Configuration').at('GatewayIpsecVpnService')
    end

    def get_edgegw_details(overview, dc, conn)
      href = overview['href']
      get_xml_object(href, conn['auth_token'], 'QueryResultRecords')
    end

    def get_edgegw_overviews(dc, conn)
      dc_xml = get_xml_object(dc['href'], conn['auth_token'], 'Vdc')
      overviews = dc_xml.search('Link[@rel="edgeGateways"]').to_a
      if overviews.length > 1
        Kernel.abort('More than 1 edge gateway found, aborting operation')
      end
      overviews[0]
    end


    def get_dc_details(conn, user_dc)
      puts conn
      org_xml = get_xml_object(conn["org_url"], conn["auth_token"], 'Org')
      all_dcs = get_all_dcs(org_xml)
      matching_dcs = all_dcs.select { |dc| /^#{user_dc}/.match(dc['name']) || user_dc == dc['name'] }
      if matching_dcs.length < 1
        all_dc_names = all_dcs.map { |dc| dc['name'] }.join(', ')
        Kernel.abort('No DCs match the search string: '+user_dc+'. All available DCs are: '+all_dc_names+'. Please use one of these')
      elsif matching_dcs.length > 1
        all_matching_names = matching_dcs.map { |dc| dc['name'] }.join(', ')
        Kernel.abort('More than 1 DC matches the search string. Please be more specific. Matching DCs are: '+all_matching_names)
      end
      matching_dcs[0]
    end


    def get_all_dcs(org_xml)
      org_xml.search('Link[@type="application/vnd.vmware.vcloud.vdc+xml"]').to_a
    end

    def get_xml_object(href, token, object_name)
      begin
        obj = nil
        uri = URI.parse(href)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request = Net::HTTP::Get.new(uri.request_uri, {'Accept' => 'application/*+xml;version=5.5', 'x-vcloud-authorization' => token})

        response = http.request(request)
        if response.code.to_i == 200
          doc = Nokogiri::XML(response.body)
          obj = doc.search(object_name).to_a
          if obj.count == 1
            return obj[0]
          else
            raise "The number of #{object_name} objects returned is not equal to 1! #{obj.inspect} "
          end
        else
          raise "Error fetch the object #{object_name}, URL: #{href}, response code: #{response.code}"
        end
      rescue Exception => e
        puts "Error fetching the object #{object_name}, URL: #{href}"
        puts e
      end
    end
  end
end
require 'test/unit'
require 'methadone'
require 'nokogiri'
require 'generator'
require 'diffy'

class TestGenerator < Test::Unit::TestCase
  def test_xml_generation
    # When I generate some XML
    input_config = YAML.load_file('test/vpn-configuration-example.yaml')
    generated_xml = Vpnconfig::Generator.new.generate_xml(input_config)

    # Then a valid XML file should be generated
    expected_file = File.open("test/expected-vpn-config.xml")
    expected_content = Nokogiri::XML(expected_file).to_xml
    expected_file.close

    puts 'generated_xml is:'
    puts generated_xml
    puts
    puts 'expected_content is'
    puts expected_content
    puts
    puts 'The difference is:'
    puts Diffy::Diff.new(generated_xml, expected_content)
    puts
    puts 'BUT ARE THEY EQUAL.....!??!?'
    puts generated_xml == expected_content
    assert(generated_xml == expected_content, 'Generated xml did not match the expected xml')
  end
end

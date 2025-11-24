#!/usr/bin/env ruby
require 'openssl'
require 'json'
require 'io/console'
require 'base64'
require 'securerandom'
require 'colorize'

class PasswordVault
  VAULT_FILE = File.expand_path('~/.password_vault.enc')
  
  def initialize
    @master_password = nil
    @passwords = {}
  end
  
  def run
    print_banner
    
    if File.exist?(VAULT_FILE)
      unlock_vault
    else
      create_new_vault
    end
    
    main_menu
  end
  
  private
  
  def print_banner
    puts "\n"
    puts "  ██████╗  █████╗ ███████╗███████╗██╗    ██╗ ██████╗ ██████╗ ██████╗ ".colorize(:magenta)
    puts "  ██╔══██╗██╔══██╗██╔════╝██╔════╝██║    ██║██╔═══██╗██╔══██╗██╔══██╗".colorize(:magenta)
    puts "  ██████╔╝███████║███████╗███████╗██║ █╗ ██║██║   ██║██████╔╝██║  ██║".colorize(:light_magenta)
    puts "  ██╔═══╝ ██╔══██║╚════██║╚════██║██║███╗██║██║   ██║██╔══██╗██║  ██║".colorize(:light_magenta)
    puts "  ██║     ██║  ██║███████║███████║╚███╔███╔╝╚██████╔╝██║  ██║██████╔╝".colorize(:light_magenta)
    puts "  ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝ ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═════╝ ".colorize(:magenta)
    puts "\n  #{' encrypted password manager '.colorize(:light_cyan).on_black}  by medusahra\n\n"
  end
  
  def create_new_vault
    puts "→ No vault found. Creating new vault...".colorize(:cyan)
    puts "\nSet your master password (this encrypts everything):".colorize(:yellow)
    password1 = get_password
    puts "\nConfirm master password:".colorize(:yellow)
    password2 = get_password
    
    if password1 != password2
      puts "\n✗ Passwords don't match!".colorize(:red)
      exit(1)
    end
    
    @master_password = password1
    save_vault
    puts "\n✓ Vault created successfully!".colorize(:green)
  end
  
  def unlock_vault
    puts "→ Enter master password to unlock vault:".colorize(:cyan)
    @master_password = get_password
    
    begin
      encrypted_data = File.read(VAULT_FILE)
      decrypted = decrypt_data(encrypted_data, @master_password)
      @passwords = JSON.parse(decrypted)
      puts "\n✓ Vault unlocked!".colorize(:green)
    rescue => e
      puts "\n✗ Wrong password or corrupted vault!".colorize(:red)
      exit(1)
    end
  end
  
  def main_menu
    loop do
      puts "\n" + "─" * 50
      puts "  [1] Add password".colorize(:light_magenta)
      puts "  [2] Get password".colorize(:light_magenta)
      puts "  [3] List all".colorize(:light_magenta)
      puts "  [4] Generate strong password".colorize(:light_magenta)
      puts "  [5] Delete password".colorize(:light_magenta)
      puts "  [6] Export vault (JSON)".colorize(:yellow)
      puts "  [0] Exit".colorize(:red)
      puts "─" * 50
      print "\n→ Choose option: ".colorize(:cyan)
      
      choice = gets.chomp
      
      case choice
      when '1' then add_password
      when '2' then get_password_entry
      when '3' then list_all
      when '4' then generate_password
      when '5' then delete_password
      when '6' then export_vault
      when '0'
        puts "\n✓ Vault locked. Goodbye!".colorize(:green)
        exit(0)
      else
        puts "\n✗ Invalid option".colorize(:red)
      end
    end
  end
  
  def add_password
    print "\nService name (e.g., GitHub, Gmail): ".colorize(:cyan)
    service = gets.chomp
    
    if @passwords[service]
      puts "✗ Entry already exists! Delete it first.".colorize(:red)
      return
    end
    
    print "Username/Email: ".colorize(:cyan)
    username = gets.chomp
    
    print "Password (or press Enter to generate): ".colorize(:cyan)
    password = get_password
    
    if password.empty?
      password = SecureRandom.alphanumeric(20)
      puts "Generated: #{password}".colorize(:green)
    end
    
    print "Notes (optional): ".colorize(:cyan)
    notes = gets.chomp
    
    @passwords[service] = {
      'username' => username,
      'password' => password,
      'notes' => notes,
      'created' => Time.now.to_s
    }
    
    save_vault
    puts "\n✓ Password saved for #{service}!".colorize(:green)
  end
  
  def get_password_entry
    print "\nService name: ".colorize(:cyan)
    service = gets.chomp
    
    if @passwords[service]
      entry = @passwords[service]
      puts "\n" + "─" * 50
      puts "  Service:  #{service}".colorize(:light_magenta)
      puts "  Username: #{entry['username']}".colorize(:light_cyan)
      puts "  Password: #{entry['password']}".colorize(:green)
      puts "  Notes:    #{entry['notes']}" unless entry['notes'].empty?
      puts "  Created:  #{entry['created']}".colorize(:light_black)
      puts "─" * 50
      
      # Copy to clipboard (macOS)
      if RUBY_PLATFORM.include?('darwin')
        IO.popen('pbcopy', 'w') { |f| f << entry['password'] }
        puts "\n✓ Password copied to clipboard!".colorize(:green)
      end
    else
      puts "\n✗ Service not found!".colorize(:red)
    end
  end
  
  def list_all
    if @passwords.empty?
      puts "\n✗ Vault is empty!".colorize(:yellow)
      return
    end
    
    puts "\n" + "─" * 50
    puts "  STORED PASSWORDS (#{@passwords.size})".colorize(:light_magenta).bold
    puts "─" * 50
    
    @passwords.keys.sort.each do |service|
      puts "  • #{service.ljust(20)} (#{@passwords[service]['username']})".colorize(:cyan)
    end
    
    puts "─" * 50
  end
  
  def generate_password
    print "\nPassword length (default 20): ".colorize(:cyan)
    length = gets.chomp
    length = length.empty? ? 20 : length.to_i
    
    charset = [('a'..'z'), ('A'..'Z'), ('0'..'9'), ['!', '@', '#', '$', '%', '^', '&', '*']].map(&:to_a).flatten
    password = (0...length).map { charset.sample }.join
    
    puts "\nGenerated password:".colorize(:green)
    puts "  #{password}".colorize(:light_green).bold
    
    if RUBY_PLATFORM.include?('darwin')
      IO.popen('pbcopy', 'w') { |f| f << password }
      puts "\n✓ Copied to clipboard!".colorize(:green)
    end
  end
  
  def delete_password
    print "\nService name to delete: ".colorize(:cyan)
    service = gets.chomp
    
    if @passwords.delete(service)
      save_vault
      puts "\n✓ Deleted #{service}!".colorize(:green)
    else
      puts "\n✗ Service not found!".colorize(:red)
    end
  end
  
  def export_vault
    filename = "vault_backup_#{Time.now.strftime('%Y%m%d_%H%M%S')}.json"
    File.write(filename, JSON.pretty_generate(@passwords))
    puts "\n✓ Vault exported to #{filename}".colorize(:green)
    puts "⚠  Keep this file secure!".colorize(:yellow)
  end
  
  def get_password
    STDIN.noecho(&:gets).chomp
  end
  
  def save_vault
    data = JSON.generate(@passwords)
    encrypted = encrypt_data(data, @master_password)
    File.write(VAULT_FILE, encrypted)
  end
  
  def encrypt_data(data, password)
    cipher = OpenSSL::Cipher.new('AES-256-CBC')
    cipher.encrypt
    
    salt = SecureRandom.random_bytes(16)
    key = OpenSSL::PKCS5.pbkdf2_hmac(password, salt, 100000, cipher.key_len, 'SHA256')
    
    cipher.key = key
    iv = cipher.random_iv
    
    encrypted = cipher.update(data) + cipher.final
    
    # Store: salt + iv + encrypted_data
    Base64.strict_encode64(salt + iv + encrypted)
  end
  
  def decrypt_data(encrypted_data, password)
    decoded = Base64.strict_decode64(encrypted_data)
    
    salt = decoded[0..15]
    iv = decoded[16..31]
    encrypted = decoded[32..-1]
    
    cipher = OpenSSL::Cipher.new('AES-256-CBC')
    cipher.decrypt
    
    key = OpenSSL::PKCS5.pbkdf2_hmac(password, salt, 100000, cipher.key_len, 'SHA256')
    
    cipher.key = key
    cipher.iv = iv
    
    cipher.update(encrypted) + cipher.final
  end
end

# Run
if __FILE__ == $0
  PasswordVault.new.run
end

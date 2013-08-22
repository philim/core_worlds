$Distance = 10000

$Messages = []

class Subsystem
	attr_accessor :cost, :type, :performance
	
	def self.types
		["engines","weapons","generator","battery","targetting computer", "repair bot", "shield capacitors", "hull plating"]
	end
	
	def purchase(ship)
		ship.credits -= @cost
		ship.subsystems[@type] = self
		ship.initialize_subsystems 
	end
	
	def generate_random(max_Cost)
		@cost = rand(max_Cost)
		@performance = (Math.sqrt(@cost)).to_i
	end
	
	def initialize(type)
			@type = type
			@performance = 50
			@cost = 0
	end			

	
	def quality
		case @performance
		when 0 then return "no"
		when 0..25 then return "really shitty"
		when 25..50 then return "pretty shitty"
		when 50..75 then return "kinda shitty"
		when 75..100 then return "meh"
		when 100..125 then return "okay"
		when 125..150 then return "sorta good"
		when 150..175 then return "good"
		when 175..200 then return "really good"
		when 200..250 then return "fucking good"
		when 250..300 then return "really fucking good"
		else return "the shit"
		end
	end
	
	def inspect
		quality + " " + @type
	end

end

class Ship
	attr_accessor :name, :health, :credits
	attr_accessor :subsystems
	attr_accessor :speed, :damage, :energy, :generator, :computer, :repair, :shields
	attr_accessor :ai_state, :ai_nextthink
	attr_accessor :max_health, :max_energy, :max_shields
		
	def inspect
	   "#{@name} Shields: #{@shields.to_i} Hull: #{@health.to_i} Energy: #{@energy.to_i}"
	end
	

	
	def system_description
		descriptions = []
			Subsystem.types.each { |subsystem_type| descriptions << @subsystems[subsystem_type].inspect } 
		descriptions
	end
	
	def initialize_subsystems
		@speed = @subsystems["engines"].performance
		@damage = @subsystems["weapons"].performance
		@computer = @subsystems["targetting computer"].performance
		@repair = @subsystems["repair bot"].performance
		
		@health = @subsystems["hull plating"].performance
		@max_health = @subsystems["hull plating"].performance
		@shields = @subsystems["shield capacitors"].performance
		@energy = @subsystems["battery"].performance
		@max_energy = @subsystems["battery"].performance
		@generator = @subsystems["generator"].performance
		@max_shields = @subsystems["shield capacitors"].performance
	end
	
	def initialize(new_name)
		@name = new_name
		
		@subsystems = {}
		Subsystem.types.each { |subsystem_type| @subsystems[subsystem_type] = Subsystem.new(subsystem_type) } 
		@subsystems["shield capacitors"].performance = 0
		@subsystems["repair bot"].performance = 0
		initialize_subsystems
		@credits = 0
	end
	
	def repair
		repair_amount = [(@repair*0.1).to_i + rand((@repair/50).to_i), @max_health - @health].min
		$Messages << "#{@name} repaired #{repair_amount.to_i} points"
		@health += repair_amount
	end
	
	def close
		distance_closed = @speed*0.1*(@energy) + rand(@speed/50)	
		$Distance -= distance_closed
		$Messages << "#{@name} closed on its target by #{distance_closed.to_i}m"
		@energy -= [10, @energy].min
	end
	
	def retreat
		distance_retreated = @speed*0.1*(@energy) + rand(@speed/50)	
		$Distance += distance_retreated
		$Messages << "#{@name} retreated from its target by #{distance_retreated.to_i}m "		
		@energy -= [10, @energy].min
	end
	
	def attack(enemy)
		damage = attack_damage
		
		$Messages << "#{@name} attacked #{enemy.name} for #{damage.to_i} points"		
		enemy.damage(attack_damage)
		@energy -= [10, @energy].min
	end
	
	def critical_hit
		rand(100) < 10
	end
	
	def damage(amount)
		damage_to_shields = [amount, @shields].min
		@shields -= damage_to_shields
		@health -= amount - damage_to_shields
		if(critical_hit)
			@health -= amount
			$Messages << " - Critical hit!"
		end
	end
	
	def attack_damage
		 @damage*(@energy*10/$Distance+0.1) + rand(@damage/50)
	end

	def power_to_divert_to_shields 
		[@energy, 10, @max_shields-@shields].min
	end

	def shields
		$Messages << "#{@name} diverted #{power_to_divert_to_shields.to_i} units of power to shields"
		energychange = power_to_divert_to_shields
		@shields += energychange
		@energy -= energychange
	end
	
	def wait
		energy_charged = [@generator/5, @max_energy-@energy].min
		$Messages << "#{@name} recharged #{energy_charged.to_i} points"
		@energy += energy_charged
	end
	
	def update
		if @energy < 0
			@energy = 0
		end
		if $Distance < 0
			$Distance = 0
		end
		if @health > @max_health
			@health = @max_health
		end
		if @energy > @max_energy
			@energy = @max_energy
		end	
	end
	
	def ai_Think(enemyship)
	
		if @ai_state == nil or @ai_nextthink <= 0
			@ai_state = ["aggressive","defensive","chaotic"].choice
			@ai_nextthink = rand(10)+5
		end
	
		case @ai_state
		when "aggressive"
			if @energy < 70
				wait
			elsif attack_damage < (enemyship.health * rand(6)*0.10)
				close
			else
				attack(enemyship)
			end
		when "defensive"
			if @energy < 20
				wait
			elsif attack_damage > 15
				retreat
			elsif @shields < 20
				shields
			elsif @energy < 90
				wait
			elsif attack_damage > 1
				attack(enemyship)
			else
				retreat
			end
		else
			if(rand(10) < 8)
				send(["wait","shields","close","retreat","repair"].choice)
			else
				attack(enemyship)
			end
		end
		
		@ai_nextthink -= 1
		
	end
end

def player_is_alive
	$playerShip.health > 0
end

def enemy_is_alive
	$enemyShip.health > 0
end

def game_choice

	if player_is_alive and !enemy_is_alive
		new_credits = 0
		new_credits += rand(10000)	
		puts "YOU FUCKING WON YOU PIECE OF SHIT HAXOR"
		puts "you gots #{new_credits} credits worth of scrap from the destruction of the enemy ship"
		$playerShip.credits += new_credits

		puts "(1) Leave spacedock to fight again"
		puts "(2) Go to the ship store and spend yo molla"
		puts "(3) Quit the game like the chump you are"
		return gets.chomp
	end

	if enemy_is_alive and !player_is_alive 
		puts "YOU LOST YOU PIECE OF SHIT. GAME OVER TRY AGAIN WHEN YOU DON'T SUCK"
		return "2"
	end

end



def performance_Description_of(value)
	case value 
	when 0 then return "no"
	when 0..25 then return "really shitty"
	when 25..50 then return "pretty shitty"
	when 50..75 then return "kinda shitty"
	when 75..100 then return "meh"
	when 100..125 then return "okay"
	when 125..150 then return "sorta good"
	when 150..175 then return "good"
	when 175..200 then return "really good"
	when 200..250 then return "fucking good"
	when 250..300 then return "really fucking good"
	else return "the shit"
	end
end

def shop_Display(ship)

	puts ""
	puts "Your Ship has:"
	puts "#{ship.credits} credits"
    puts ship.system_description 
    puts ""


	item_Number = 0
	items = {}
	
	total_cost_so_far = 0

	begin
	item_Number += 1
	items[item_Number] = Subsystem.new(Subsystem.types.choice)
	items[item_Number].generate_random(ship.credits)
	
	total_cost_so_far += items[item_Number].cost
	
	puts "(#{item_Number}) Buy "+items[item_Number].inspect+". Performance: "+items[item_Number].performance.to_s+" Cost: "+items[item_Number].cost.to_s
	
		
	end while item_Number <10
	
	
	item_choice = gets.chomp
	
	items[item_choice.to_i].purchase(ship)
	puts ship.system_description

end

def main_Display

puts ""
while $Messages.size > 0
	puts $Messages.pop
end
puts ""
puts $playerShip.inspect
puts $enemyShip.inspect
puts "Distance : #{$Distance.to_i}m"
puts ""
puts "(1) Close on Target"
puts "(2) Retreat from Target"
puts "(3) Attack Target"
puts "(4) Divert power to shields"
puts "(5) Repair"
puts "(6) Wait - Charge Energy"
puts ""

choice = gets.chomp

return choice

end

puts "Enter your ship's name, captain."
playershipname = gets.chomp

$playerShip = Ship.new(playershipname)

$playerShip.credits = 50000

shop_Display $playerShip

begin

$enemyShip = Ship.new("Enemy Ship")

begin

	choice = main_Display

	case choice
	when "1"
		$playerShip.close
	when "2"
		$playerShip.retreat
	when "3"
		$playerShip.attack($enemyShip)
	when "4"
		$playerShip.shields	
	when "5"
		$playerShip.repair
	else
		$playerShip.wait		
	end

	$enemyShip.ai_Think($playerShip)
	
	$playerShip.update
	$enemyShip.update
	

end while $Distance < 20000 and player_is_alive and enemy_is_alive


end while game_choice == "1"

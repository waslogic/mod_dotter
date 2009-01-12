class Class
  def to_dot
    name = self.to_s.split(/::/).last
    escape = lambda {|s, x| s += (x.gsub(/[\[\]<>\|]/) {|y| "\\#{y}" } + '\l') }
    methods = [:public_instance_methods, :protected_instance_methods, :private_instance_methods].map {|m| self.send(m, nil).sort.inject('', &escape) }.join('|')
    "\"#{name}\" [shape=Mrecord, label=\"{#{name}|#{methods}}\"]"
  end
end

class Module
  def to_diagram(directional=false)
    if directional == true
      type = 'digraph'
      connector = '->'
    else
      type = 'graph'
      connector = '--'
    end
    "#{type} #{self}_diagram {\n\tgraph[overlap=false, splines=true]\n#{mrecords}\n\n#{connections(connector)}\n}"
  end

  def to_dot
    name = self.to_s.split(/::/).last
    escape = lambda {|s, x| s += (x.gsub(/[\[\]<>\|]/) {|y| "\\#{y}" } + '\l') }
    methods = [:public_instance_methods, :protected_instance_methods, :private_instance_methods].map {|m| self.send(m, nil).sort.inject('', &escape) }.join('|')
    "\"#{name}\" [shape=Mrecord, fillcolor=pink2, style=filled, label=\"{#{name}|#{methods}}\"]"
  end

  private
  def klasses
    self.constants.map {|x| self.const_get(x) if self.const_get(x).class == Class }.compact
  end

  def mods
    self.constants.map {|x| self.const_get(x) if self.const_get(x).class == Module }.compact
  end

  def mrecords
    as_str = lambda {|a,b| a.to_s <=> b.to_s }
    (mods.sort(&as_str) + klasses.sort(&as_str)).map{|r| "\t" + r.to_dot }.join("\n")
  end

  def mixins
    namerize = lambda {|s| s.to_s.split('::').last }
    klasses.inject({}) do |h, klass|
      (klass.ancestors.select {|x| x.to_s =~ /^#{self}::/ } - [klass]).each do |m|
        m_name = namerize[m]
        h[m_name] ||= []
        h[m_name] << namerize[klass]
      end
      h
    end
  end

  def connections(connector='->')
    mixins.inject('') {|s, (mod, list)| s << "\t\"#{mod}\" #{connector} {#{list.map {|x| "\"#{x}\""}.join('; ')}}\n" }
  end
end

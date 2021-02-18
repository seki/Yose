require_relative '../lib/yose'
require 'date'

class ShiftStore
  def initialize
    @db = Yose::Store.new
  end
  attr_reader :db

  def add_employee(name)
    user = {
      'type' => '従業員',
      'name' => name
    }
    @db.alloc!(user.to_json)
  end

  def all_employee
    @db.search({'type' => '従業員'})
  end

  def employee_by_name(name)
    @db.search({'type' => '従業員', 'name' => name})
  end

  def employee_by_store(store)
    @db.search({'type' => '従業員', '店' => [store]})
  end

  def add_plan(employee_uid, store, y, m, d, hhmm, hours)
    plan = {
      'type' => '予定',
      '従業員' => employee_uid,
      '店' => store,
      'y' => y,
      'm' => m,
      'd' => d,
      'start' => hhmm,
      'hours' => hours
    }
    @db.alloc!(plan) rescue nil
  end
end

if __FILE__ == $0
  app = ShiftStore.new

  seki = app.add_employee('関将俊') rescue app.employee_by_name('関将俊').first['uid']
  ikezawa = app.add_employee('池澤一廣') rescue app.employee_by_name('池澤一廣').first['uid']
  pp app.all_employee
  seki = app.employee_by_name('関将俊').first['uid']
  pp app.db[seki]
  app.db.update(seki, {'店' => %w(矢板 西那須野 大田原)})
  pp app.db[seki]
  pp app.employee_by_name('関将俊')
  pp app.employee_by_name('池澤一廣')
  app.db.merge(ikezawa, {'店' => %w(矢板)})
  miwa = app.add_employee('深谷美和') rescue nil
  if miwa
    app.db.merge(miwa, {'店' => %w(大田原 矢板)})
  end
  puts '矢板'
  pp app.employee_by_store('矢板').map{|x| x['obj']}
  puts '大田原'
  pp app.employee_by_store('大田原').map{|x| x['obj']}
  puts '西那須野'
  pp app.employee_by_store('西那須野').map{|x| x['obj']}


  s = Date.parse('2021-01-01')
  (s ... (s >> 2)).each do |d|
    app.add_plan(ikezawa, '矢板', d.year, d.month, d.day, '8:00', 4)
    app.add_plan(ikezawa, '矢板', d.year, d.month, d.day, '13:00', 4)
    app.add_plan(miwa, '大田原', d.year, d.month, d.day, '13:00', 4)
    app.add_plan(seki, '大田原', d.year, d.month, d.day, '8:00', 4)
    app.add_plan(seki, '西那須野', d.year, d.month, d.day, '13:00', 4)
  end

  employee = Hash.new do |h, k|
    h[k] = app.db[k].dig("name") rescue nil
  end
  pp app.db.search({"type" => "予定", "店" => "大田原", "y" => 2021, "m" => 2}).map {|x|
    it = x['obj']
    [employee[it['従業員']]] + it.values_at(* %w(y m d start hours))
  }

  pp app.db.search({"type" => "予定", "店" => "矢板", "y" => 2021, "m" => 2}).map {|x|
    it = x['obj']
    [employee[it['従業員']]] + it.values_at(* %w(y m d start hours))
  }
end


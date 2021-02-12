require 'test-unit'
require_relative '../lib/yose'

class YoseTest<Test::Unit::TestCase
  TABLE_NAME = 'removeme'
  def self.startup
    begin
      Yose::create_table(TABLE_NAME)
    rescue
      puts "panic: create_table failed. table #{TABLE_NAME} is exists, exit!."
      exit!
    end
  end

  def self.shutdown
    Yose::drop_table(TABLE_NAME)
  end

  def setup
    @store = Yose::Store.new(TABLE_NAME)
  end

  def teardown
    Yose::DB.instance.conn.exec("delete from #{TABLE_NAME}")
  end

  def test_alloc
    assert(@store.alloc!({"foo" => "bar"}))
    assert(@store.alloc({"foo" => "bar"}))
    assert_raise {@store.alloc!({"foo" => "bar"})}
    assert(@store.alloc!({"foo" => "baz"}))
  end

  def test_update
    one = @store.alloc({"foo" => "bar", "bar" => "baz"})
    assert(one)
    @store.update(one, {"foo" => "hoge"})

    assert_equal(["hoge", "baz"], @store.fetch(one).values_at("foo", "bar"))
  end
end
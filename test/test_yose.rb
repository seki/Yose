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

  def test_merge
    one = @store.alloc({"foo" => "bar", "bar" => "baz"})
    assert(one)
    it = @store.merge(one, {"foo" => "hoge"})
    assert_equal(["hoge", "baz"], it.values_at("foo", "bar"))
    assert_equal(["hoge", "baz"], @store[one].values_at("foo", "bar"))
  end

  def test_replace
    one = @store.alloc({"foo" => "bar", "bar" => "baz"})
    assert(one)
    it = @store.replace(one, {"hoge" => "fuga"})
    assert_equal({"hoge" => "fuga"}, it)
    assert_equal({"hoge" => "fuga"}, @store[one])
  end

  def test_free
    one = @store.alloc({"foo" => "bar", "bar" => "baz"})
    assert(one)
    it = @store.free(one)
    assert_equal({"foo" => "bar", "bar" => "baz"}, it)
    assert_equal(nil, @store[one])
  end

  def test_delete
    one = @store.alloc({"foo" => "bar", "bar" => "baz"})
    assert(one)
    it = @store.delete(one, "bar")
    assert_equal({"foo" => "bar"}, it)
    assert_equal({"foo" => "bar"}, @store[one])
  end

  def test_mtime_recent
    one = @store.alloc({"foo" => "bar", "bar" => "baz"})
    two = @store.alloc({"foo" => "bar", "bar" => "baz"})
    mtime = @store.mtime(two)
    three = @store.alloc({"foo" => "bar", "bar" => "baz"})
    assert_equal(1, @store.recent(mtime).size)
    ary = @store.recent(@store.mtime(one))
    assert_equal(2, ary.size)
    assert_equal(three, ary[0]['uid'])
    assert_equal(two, ary[1]['uid'])
  end
end
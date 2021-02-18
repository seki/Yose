# Yose
Simple JSON DB using psql, jsonb, ruby

# setup PG

create database 'yose'

```
% createdb yose
```

or use existing database, 

```
% export YOSE_DATABASE_URL=existing_database
```
```
% export DATABASE_URL=existing_database
```

searching order:
```
url = ENV['YOSE_DATABASE_URL'] || ENV['DATABASE_URL'] || 'postgres:///yose'
```

# usage

## create_table, drop_table

default table name is 'world'.

```
irb(main):001:0> Yose::create_table
irb(main):002:0> Yose::create_table('world')
...
PG::DuplicateTable (ERROR:  relation "world" already exists)
irb(main):003:0> Yose::drop_table('world')
irb(main):004:0> Yose::create_table('world')
```

```
irb(main):007:0> Yose::create_table('another')
irb(main):008:0> Yose::drop_table('another')
```

## alloc jsonb object

alloc, and free. alloc retruns the UID.

```
% irb -r yose --simple-prompt
>> root = Yose::Store.new
>> it
=> "f51a923e-99aa-41f0-9b9f-e3b596b66aa9"
>> it = root.alloc({'foo' => 'bar', 'ary' => [1, 2, 3]}.to_json)
>> root[it]
=> {"ary"=>[1, 2, 3], "foo"=>"bar"}
>> root.free(it)
=> {"ary"=>[1, 2, 3], "foo"=>"bar"}
>> root[it]
=> nil
```

for Hash, obj.to_json automatically.

```
>> it = root.alloc({'foo' => 'bar', 'ary' => [1, 2, 3]})
>> root[it]
=> {"ary"=>[1, 2, 3], "foo"=>"bar"}
```

alloc! checks for uniqueness. (using @> op.)

```
>> root.alloc!({'type' => 'employee', 'name' => '@m_seki'})
=> "ed98d46c-673a-4dd2-838f-194e42291f2f"
>> root.alloc!({'type' => 'employee', 'name' => '@m_seki'})
...
RuntimeError (already exist {"type":"employee","name":"@m_seki"})
>> root.alloc!({'type' => 'employee', 'name' => '@awazeki'})
=> "39bfdf2b-4fa1-4320-9cff-efbce77b6cea"
>> root.alloc!({'type' => 'employee'})
...
RuntimeError (already exist {"type":"employee"})
>> root.alloc!({'type' => 'author', 'name' => '@m_seki'})
=> "2d0b596d-bc09-4687-a9d5-9dec087ad9df"
```

## search

```
>> pp root.search({'type' => 'employee'})
[{"uid"=>"ed98d46c-673a-4dd2-838f-194e42291f2f",
  "obj"=>{"name"=>"@m_seki", "type"=>"employee"},
  "mtime"=>2021-02-18 18:37:30.220031 +0900},
 {"uid"=>"39bfdf2b-4fa1-4320-9cff-efbce77b6cea",
  "obj"=>{"name"=>"@awazeki", "type"=>"employee"},
  "mtime"=>2021-02-18 18:37:42.337694 +0900}]
>> pp root.search({'name' => '@m_seki'})
[{"uid"=>"ed98d46c-673a-4dd2-838f-194e42291f2f",
  "obj"=>{"name"=>"@m_seki", "type"=>"employee"},
  "mtime"=>2021-02-18 18:37:30.220031 +0900},
 {"uid"=>"2d0b596d-bc09-4687-a9d5-9dec087ad9df",
  "obj"=>{"name"=>"@m_seki", "type"=>"author"},
  "mtime"=>2021-02-18 18:37:56.323186 +0900}]
>> pp root.search({'name' => '@m_seki', 'type' => 'author'})
[{"uid"=>"2d0b596d-bc09-4687-a9d5-9dec087ad9df",
  "obj"=>{"name"=>"@m_seki", "type"=>"author"},
  "mtime"=>2021-02-18 18:37:56.323186 +0900}]
```

## merge (update), delete

update merges jsonb object. (using || op.)

delete delets jsonb object. (using - op.)

```
>> root[it].update({'ary' => 'not ary'})
=> {"ary"=>"no ary", "foo"=>"bar"}
>> root[it]
=> {"ary"=>[1, 2, 3], "foo"=>"bar"}
>> root.update(it, {'ary' => 'not ary'})
=> {"ary"=>"not ary", "foo"=>"bar"}
>> root[it]
=> {"ary"=>"not ary", "foo"=>"bar"}
>> root.delete(it, 'ary')
=> {"foo"=>"bar"}
>> root[it]
=> {"foo"=>"bar"}
>> root.merge(it, {'hash' => {'foo' => 'bar', 'bar' => 'baz'}})
=> {"foo"=>"bar", "hash"=>{"bar"=>"baz", "foo"=>"bar"}}
>> root[it]
=> {"foo"=>"bar", "hash"=>{"bar"=>"baz", "foo"=>"bar"}}
```

## mtime and recent changes

```
>> he = root.search({'type' => 'employee', 'name' => '@awazeki'}).dig(0, 'uid')
>> root[he]
=> {"name"=>"@awazeki", "type"=>"employee"}
>> root.mtime(he)
=> 2021-02-18 18:37:42.337694 +0900
```

```
>> pp root.recent(root.mtime(he))
[{"uid"=>"3e13e180-e5fc-4179-9f4c-d8fbb5fe9bf4",
  "obj"=>{"foo"=>"bar", "hash"=>{"bar"=>"baz", "foo"=>"bar"}},
  "mtime"=>2021-02-18 18:42:42.658912 +0900},
 {"uid"=>"2d0b596d-bc09-4687-a9d5-9dec087ad9df",
  "obj"=>{"name"=>"@m_seki", "type"=>"author"},
  "mtime"=>2021-02-18 18:37:56.323186 +0900}]
```

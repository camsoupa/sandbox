
n=5
arr=(0..1000000).to_a


#fastest
def n_gram_1 arr, n
  (0..arr.size-n).map { |i| arr.slice(i, n) }
end

def n_gram_2 arr, n
  arr.each_cons(n).to_a
end

def n_gram_3 arr, n
  arr[0..-n].each_index.map { |i| arr.slice(i, n) }
end


start = Time.now.to_f
n_gram_1(arr, n)
finish = Time.now.to_f
puts finish-start

start = Time.now.to_f
n_gram_2(arr, n)
finish = Time.now.to_f
puts finish-start

start = Time.now.to_f
n_gram_3(arr, n)
finish = Time.now.to_f
puts finish-start

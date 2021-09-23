require 'minitest/autorun'
require 'timeout'

class CustomerSuccessBalancing
  attr_reader :customer_success, :customers, :away_customer_success

  def initialize(customer_success, customers, away_customer_success)
    @customer_success = customer_success.sort_by { |cs| cs[:score] }
    @customers = customers.sort_by { |cs| cs[:score] }
    @away_customer_success = away_customer_success
  end

  def execute
    remove_away_customer_success

    fetch_winner_cs_id(create_customers_and_cs_list)
  end

  private

  def remove_away_customer_success
    customer_success.delete_if{ |item| away_customer_success.include?(item[:id])}
  end

  def define_cs_id(customer)
    customer_success.bsearch { |cs| cs[:score] >= customer[:score] }[:id]
  rescue
    0
  end

  def create_customers_and_cs_list
    customers.map { |customer| { customer_id: customer[:id], cs_id: define_cs_id(customer) } }
  end

  def fetch_winner_cs_id(customers_and_cs_list)
    rule_to_set_cs_id = 0
    winner_cs_id = 0

    customer_success.each do |cs|
      total_attendings_by_cs = customers_and_cs_list.select { |item| item[:cs_id] == cs[:id] }.count

      if total_attendings_by_cs > rule_to_set_cs_id
        rule_to_set_cs_id = total_attendings_by_cs
        winner_cs_id = cs[:id]
      elsif total_attendings_by_cs == rule_to_set_cs_id and total_attendings_by_cs.positive?
        rule_to_set_cs_id = total_attendings_by_cs
        winner_cs_id = 0
      end
    end

    winner_cs_id
  end
end

class CustomerSuccessBalancingTests < Minitest::Test
  def test_scenario_one
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    balancer = CustomerSuccessBalancing.new(
      build_scores([11, 21, 31, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    balancer = CustomerSuccessBalancing.new(
      build_scores(Array(1..999)),
      build_scores(Array.new(10000, 998)),
      [999]
    )
    result = Timeout.timeout(1.0) { balancer.execute }
    assert_equal 998, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(
      build_scores([1, 2, 3, 4, 5, 6]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 2, 3, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [1, 3, 2]
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [4, 5, 6]
    )
    assert_equal 3, balancer.execute
  end

  private

  def build_scores(scores)
    scores.map.with_index do |score, index|
      { id: index + 1, score: score }
    end
  end
end

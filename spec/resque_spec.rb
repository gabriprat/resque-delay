require_relative 'spec_helper'
require 'logger'
require 'resque-delay'

describe "resque" do
  context 'delay' do
    class FairyTail
      attr_accessor :happy_ending
      def self.princesses; end
      def tell
        @happy_ending = true
      end
    end
    
    before do
      Resque.queues.each{|q| Resque.redis.del "queue:#{q}" } #Empty all queues
      Resque.remove_delayed_selection do true end #Remove all delayed jobs
    end
    
    it 'creates a new PerformableMethod job' do
      expect do
        job = 'hello'.delay.count('l')
        expect(job.class).to eq(ResqueDelay::PerformableMethod)
        expect(job.method).to eq(:count)
        expect(job.args).to eq(['l'])
      end.to change { Resque.info[:pending] }.by(1)
    end

    it 'sets default queue name' do
      job = FairyTail.delay(to: 'abbazabba').to_s
      expect(job.queue).to eq('abbazabba')
    end

    it 'sets job in the future' do
      expect do
        run_in = 1 * 3600 * 24
        job = FairyTail.delay(in: run_in).to_s
        expect(job.run_in).to eq(run_in)
      end.to change { Resque.delayed_queue_schedule_size }.by(1)
    end
    
    it 'fails if in option is not valid' do
      expect do
        job = FairyTail.delay(in: 'I will fail').to_s
      end.to raise_error { ::ArgumentError }
    end
    
  end
end

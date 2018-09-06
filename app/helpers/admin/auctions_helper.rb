module Admin::AuctionsHelper
  def current_auction?(auction)
    auction == current_auction
  end

  def money
    auctions = Auction.all
    total = 0
    auctions.each do |auction|
      if auction.status == 'finished'
        price_bid = auction.auction_details.order('price_bid DESC').first.price_bid
        price = auction.timer.product.price
        total += (price_bid - price)
      end
    end
    total
  end
end

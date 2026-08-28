import {
  InlineCitationCarousel,
  InlineCitationCarouselContent,
  InlineCitationCarouselHeader,
  InlineCitationCarouselIndex,
  InlineCitationCarouselItem,
  InlineCitationCarouselNext,
  InlineCitationCarouselPrev,
  InlineCitationSource,
} from "@upstream/ai_elements/inline-citation";

const sources = [
  {
    title: "Advances in Natural Language Processing",
    url: "https://example.com/nlp-advances",
    description: "A study of recent natural language processing systems.",
  },
  {
    title: "Breakthroughs in Machine Learning",
    url: "https://mlnews.org/breakthroughs",
    description: "A review of important machine learning results.",
  },
];

export default function InlineCitationCarouselExample() {
  return (
    <div className="w-80">
      <h3 className="sr-only">Sources</h3>
      <InlineCitationCarousel
        aria-label="Citation sources"
        id="citation-carousel"
      >
        <InlineCitationCarouselHeader>
          <InlineCitationCarouselPrev />
          <InlineCitationCarouselNext />
          <InlineCitationCarouselIndex />
        </InlineCitationCarouselHeader>
        <InlineCitationCarouselContent>
          {sources.map((source) => (
            <InlineCitationCarouselItem key={source.url}>
              <InlineCitationSource {...source} />
            </InlineCitationCarouselItem>
          ))}
        </InlineCitationCarouselContent>
      </InlineCitationCarousel>
    </div>
  );
}

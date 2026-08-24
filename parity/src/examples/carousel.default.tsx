import {
  Carousel,
  CarouselContent,
  CarouselItem,
  CarouselNext,
  CarouselPrevious,
} from "@upstream/shadcn/ui/carousel";

// Ported from `StorybookWeb.Examples.carousel_default/1`.
export default function CarouselDefault() {
  return (
    <Carousel aria-label="Recent updates" className="mx-12 max-w-md">
      <CarouselContent>
        {["Spec", "Generator", "Browser"].map((update) => (
          <CarouselItem key={update}>
            <div className="border bg-card p-6 text-card-foreground shadow-sm">
              <p className="font-medium">{update}</p>
              <p className="mt-1 text-sm text-muted-foreground">
                One component state, owned in the right place.
              </p>
            </div>
          </CarouselItem>
        ))}
      </CarouselContent>
      <CarouselPrevious />
      <CarouselNext />
    </Carousel>
  );
}

# Aquarius MX 3D Printed Case
This folder contains the STL (STereoLithogray) files needed to 3D print an enclosure for the Aquarius MX.

## Files
- **aq_mx_base_template.stl** - This is a template for consistently applying the rubber feet and bottom label in the correct position on the bottom of the case.
- **aq_mx_case_bottom.stl** - This is the bottom or base of the Aquarius MX case.
- **aq_mx_case_top.stl** - This is the top or cover of the Aquarius MX case.
- **aq_mx_pcb_feet.stl** - This is a set of feet that can be used instead of a case to hold the PCB at the proper height.

## FDM Printing
The typical method people will use to print the Aquarius MX case is FDM (Fused Deposition Modeling), the most common and cost-effective means to create a 3D printed enclosure. For the Aquarius MX case, here are the recommended specifications for FDM printing.

- **Material** - It is recommended that both components of the Aquarius MX case be printed in PLA (PolyLactic Acid) plastic rather than ABS (Acrylonitrile Butadiene Styrene) plastic, due to the large, flat surface features of the case. ABS is more prone to warping in the corners, and this can create an offset of the plane which keeps the PCB flat and even with the expansion port of the Aquarius computer. A heated build surface is strongly encouraged, particularly with the top of the case, as an embossed Aquarius MX logo is featured, and usually sticks better to a heated surface.
- **Nozzle Diameter** - A typical 0.4mm nozzle works fine
- **Layer Height** - A layer height of between 0.2mm and 0.4mm offers a good range of speed/surface quality.
- **Build Area** - The 3D printer must support a build size of 212.1mm x 120.9mm x 65.3mm / 8.5" x 4.75" x 2.125" to print the largest of the two parts (the top).
- **Support Material** - Standard square supports are recommended. Tree supports do not offer the best results. We don't require a brim or raft, but if you use these, remember to account for this in your build volume dimensions. 

### PLA Part Printing Orientation
- **Bottom** - This part should be printed with the BOTTOM facing down on the build surface, and support material is generated under the "neck" and inside the alignment notches on the neck. Using the above recommended settings, the BOTTOM piece will typically take 10 to 14 hours to complete, and will consume about 90g of PLA filament.
- **Top** - This part should be printed with the TOP facing down on the build surface, and support material is generated beneath the top "ramp" and inside the cartridge alignment guides. Note that this part features an embossed Aquarius MX logo, which prints best if a heated build surface is used. Some printers benefit from additional build surface adhesive, such as glue stick or hairspray, but go with what you're used to doing. Using the above recommended settings, the BOTTOM piece will typically take 13 to 19 hours to complete, and will consume about 114g of PLA filament

## SLA Resin Printing
Some manufacturers such as JLCPCB offer SLA (StereoLithogrAphy) resin printing for about US$20 for the two parts of the case, but shipping will usually add another US$30-40. Due to the volume and dimensions of the Aquarius MX case, SLA resin printing is not practical for most consumer-grade resin printers.

## SLS/MFJ Printing
If you have access to a high-end SLS (Selective Laser Sintering) or MJF (MultiJet Fusion) printer, these produce EXCEPTIONAL results, but at a significant cost. Most service bureaus will charge approximately US$200 for the two parts of the case, plus shipping.

## Finishing
- The case can be printed in a light beige color to approximate the Aquarius plastic (see BOM for details), or in black. The parts can alternately be printed in any color, then primed, filled and painted to suit your needs. Note that there are fine details in the embossed logo that can be lost if a filler primer is used, and some of the parts of the case that join with the Aquarius are tight, and can cause some paints to rub off if not sealed and/or lubricated properly.
- The case uses four 1/2" #4 pan head screws to attach the top and bottom halves. A metal "thread cutting" screw designed for plastic is recommended. See BOM for details.
- The finished case will also need four rubber feet for the bottom to bring the case up to the proper height for alignment with the Aquarius cartridge port. See BOM for details. You can print and use the **aq_mx_base_template** file for accurate positioning of these rubber feet.

## PCB Feet
The PCB feet file can be used instead of printing a full case for the Aquarius MX. These feet print in less than 1 hour on most FDM printers, and can be screwed to the bottom of the PCB through the mounting holes using the same screws that would hold the full case together. This maintains the PCB at a plane that is inline with the Expansion Port on the Aquarius Computer. This is important because if the PCB is at an angle (too high or too low), the contact between the computer and the expander PCB can be lost, and will cause the Aquarius MX (or the computer) to malfunction or become damaged. After printing, the four feet must be separated from one another to fit in each of the four corner PCB mounting holes. The "flashing" at the bottom edges between the feet should be trimmed off or sanded for best results.

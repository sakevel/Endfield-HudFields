#include "patch.hpp"
#include "fixture.hpp"
#include <filesystem>
#include <fstream>
#include <iostream>
#include <iterator>
#include <stdexcept>
void check(bool ok) { if (!ok) throw std::runtime_error("Patch assertion failed"); }
std::string read(const std::filesystem::path& p) {
    std::ifstream f(p, std::ios::binary); if (!f) throw std::runtime_error("Fixture read failed");
    return {std::istreambuf_iterator<char>(f), {}};
}
int main(int argc, char** argv) {
    try {
        const std::string extension="return {bind=function()end,updated=function()end,close=function()end}";
        const auto original=fixture(); std::string output;
        check(hud_fields::patch(original, extension, output));
        check(output.find("_zmlHudFields.bind(self)\nend") != output.npos);
        check(output.find("_zmlHudFields.updated(self, clampPingValue)") != output.npos);
        std::string sentinel="unchanged";
        for (const auto& bad : {std::string("broken"), output,
             original+"\nHL.Commit(UIDPanelCtrl)", original+"\n"+original}) {
            check(!hud_fields::patch(bad,extension,sentinel) && sentinel=="unchanged");
        }
        for (auto anchor : {"UIDPanelCtrl = HL.Class", "UIDPanelCtrl.OnClose", "NetClientInst:GetPing()",
                            "self.view.pingCon.gameObject:SetActive(enablePing)", "clampPingValue)\n"}) {
            auto bad=original; auto pos=bad.find(anchor); check(pos != bad.npos);
            bad.erase(pos,std::string_view(anchor).size());
            check(!hud_fields::patch(bad,extension,sentinel) && sentinel=="unchanged");
        }
        check(!hud_fields::patch(original,"",sentinel));
        auto crlf=original;
        for(size_t p=0;(p=crlf.find('\n',p))!=crlf.npos;p+=2) crlf.insert(p,"\r");
        check(hud_fields::patch(crlf,extension,sentinel) && sentinel==output);
        if(argc==4) {
            check(hud_fields::patch(read(argv[1]),read(argv[2]),output));
            if(std::filesystem::exists(argv[3])) throw std::runtime_error("Refusing fixture overwrite");
            std::ofstream file(argv[3],std::ios::binary); file<<output; file.close(); check(bool(file));
        }
        std::cout<<"PASS: atomic contracts, missing/duplicate/already-patched, CRLF, optional actual client fixture\n";
    } catch(const std::exception& e) {std::cerr<<e.what()<<'\n';return 1;}
}
